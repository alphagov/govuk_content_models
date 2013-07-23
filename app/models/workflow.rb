require "differ"
require "state_machine"
require "action"

module Workflow
  class CannotDeletePublishedPublication < RuntimeError; end
  extend ActiveSupport::Concern

  included do
    validate :not_editing_published_item
    before_destroy :check_can_delete_and_notify

    before_save :denormalise_users
    after_create :notify_siblings_of_new_edition

    field :state, type: String, default: "lined_up"
    belongs_to :assigned_to, class_name: "User"
    embeds_many :actions

    state_machine initial: :lined_up do
      after_transition on: :request_amendments do |edition, transition|
        edition.mark_as_rejected
      end

      after_transition on: :publish do |edition, transition|
        edition.was_published
      end

      event :start_work do
        transition lined_up: :draft
      end

      event :request_review do
        transition [:draft, :amends_needed] => :in_review
      end

      event :approve_review do
        transition in_review: :ready
      end

      event :approve_fact_check do
        transition fact_check_received: :ready
      end

      event :request_amendments do
        transition [:fact_check_received, :in_review] => :amends_needed
      end

      # Editions can optionally be sent out for fact check
      event :send_fact_check do
        transition ready: :fact_check
      end

      # If no response is received to a fact check request we can skip
      # that fact check and return the edition to the 'ready' state
      event :skip_fact_check do
        transition fact_check: :ready
      end

      # Where a fact check response has been received the item is moved
      # into a special state so that the fact check responses can be
      # reviewed
      event :receive_fact_check do
        transition fact_check: :fact_check_received
      end

      event :publish do
        transition ready: :published
      end

      event :emergency_publish do
        transition draft: :published
      end

      event :archive do
        transition all => :archived, :unless => :archived?
      end
    end

    # alias_method :created_by, :creator
    # alias_method :published_by, :publisher
    # alias_method :archived_by, :archiver
  end

  def fact_checked?
    (self.actions.where(request_type: Action::APPROVE_FACT_CHECK).count > 0)
  end

  def capitalized_state_name
    self.human_state_name.capitalize
  end

  def update_user_action(property, statuses)
    actions.where(:request_type.in => statuses).limit(1).each do |action|
      # This can be invoked by Panopticon when it updates an artefact and associated
      # editions. The problem is that Panopticon and Publisher users live in different
      # collections, but share a model and relationships with eg actions.
      # Therefore, Panopticon might not find a user for an action.
      if action.requester
        self[property] = action.requester.name
      end
    end
  end

  def denormalise_users
    self.assignee = assigned_to.name if assigned_to
    update_user_action("creator",   [Action::CREATE, Action::NEW_VERSION])
    update_user_action("publisher", [Action::PUBLISH])
    update_user_action("archiver",  [Action::ARCHIVE])
    self
  end

  def created_by
    creation = actions.detect do |a|
      a.request_type == Action::CREATE || a.request_type == Action::NEW_VERSION
    end
    creation.requester if creation
  end

  def published_by
    publication = actions.where(request_type: Action::PUBLISH).first
    publication.requester if publication
  end

  def archived_by
    publication = actions.where(request_type: Action::ARCHIVE).first
    publication.requester if publication
  end

  def latest_status_action(type = nil)
    if type
      self.actions.where(request_type: type).last
    else
      most_recent_action(&:status_action?)
    end
  end

  def last_fact_checked_at
    last_fact_check = actions.reverse.find(&:is_fact_check_request?)
    last_fact_check ? last_fact_check.created_at : NullTimestamp.new
  end

  def new_action(user, type, options={})
    actions.create!(options.merge(requester_id: user.id, request_type: type))
  end

  def new_action_without_validation(user, type, options={})
    action = actions.build(options.merge(requester_id: user.id, request_type: type))
    save(validate: false)
    action
  end

  def most_recent_action(&blk)
    self.actions.sort_by(&:created_at).reverse.find(&blk)
  end

  def not_editing_published_item
    if changed? and ! state_changed?
      if archived?
        errors.add(:base, "Archived editions can't be edited")
      end
      if published?
        changes_allowed_when_published = ["slug", "section",
                                          "department", "business_proposition"]
        illegal_changes = changes.keys - changes_allowed_when_published
        if illegal_changes.empty?
          # Allow it
        else
          errors.add(:base, "Published editions can't be edited")
        end
      end
    end
  end

  def can_destroy?
    ! published? and ! archived?
  end

  def check_can_delete_and_notify
    raise CannotDeletePublishedPublication unless can_destroy?
  end

  def mark_as_rejected
    self.inc(:rejected_count, 1)
  end

  def previous_edition
    self.previous_published_edition || false
  end

  def edition_changes
    if self.whole_body.empty?
      false
    else
      my_body, their_body = [self, self.published_edition].map do |edition|
        edition.whole_body.gsub("\r\n", "\n")
      end
      Differ.diff_by_line(my_body, their_body)
    end
  end

  def notify_siblings_of_new_edition
    siblings.update_all(sibling_in_progress: self.version_number)
  end

  def notify_siblings_of_published_edition
    siblings.update_all(sibling_in_progress: nil)
  end

  def update_sibling_in_progress(version_number_or_nil)
    update_attribute(:sibling_in_progress, version_number_or_nil)
  end

  def in_progress?
    ! ["archived", "published"].include? self.state
  end
end
