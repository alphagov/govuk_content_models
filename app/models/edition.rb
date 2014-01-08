require "workflow"
require "fact_check_address"

class Edition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Workflow

  field :panopticon_id,        type: String
  field :version_number,       type: Integer,  default: 1
  field :sibling_in_progress,  type: Integer,  default: nil
  field :business_proposition, type: Boolean,  default: false

  field :title,                type: String
  field :created_at,           type: DateTime, default: lambda { Time.zone.now }
  field :overview,             type: String
  field :alternative_title,    type: String
  field :slug,                 type: String
  field :section,              type: String
  field :department,           type: String
  field :rejected_count,       type: Integer,  default: 0
  field :tags,                 type: String

  field :assignee,             type: String
  field :creator,              type: String
  field :publisher,            type: String
  field :archiver,             type: String

  GOVSPEAK_FIELDS = []

  belongs_to :assigned_to, class_name: "User"

  scope :lined_up,            where(state: "lined_up")
  scope :draft,               where(state: "draft")
  scope :amends_needed,       where(state: "amends_needed")
  scope :in_review,           where(state: "in_review")
  scope :fact_check,          where(state: "fact_check")
  scope :fact_check_received, where(state: "fact_check_received")
  scope :ready,               where(state: "ready")
  scope :published,           where(state: "published")
  scope :archived,            where(state: "archived")
  scope :in_progress,         where(:state.nin => ["archived", "published"])
  scope :assigned_to,         lambda { |user|
    if user
      where(assigned_to_id: user.id)
    else
      where(:assigned_to_id.exists => false)
    end
  }

  validates :title, presence: true
  validates :version_number, presence: true
  validates :panopticon_id, presence: true
  validates_with SafeHtml

  before_save :check_for_archived_artefact
  before_destroy :destroy_artefact

  index "assigned_to_id"
  index "panopticon_id"
  index "state"

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []

  alias_method :admin_list_title, :title

  def series
    Edition.where(panopticon_id: panopticon_id)
  end

  def history
    series.order([:version_number, :desc])
  end

  def siblings
    series.excludes(id: id)
  end

  def previous_siblings
    siblings.where(:version_number.lt => version_number)
  end

  def subsequent_siblings
    siblings.where(:version_number.gt => version_number)
  end

  def latest_edition?
    subsequent_siblings.empty?
  end

  def published_edition
    series.where(state: "published").order(version_number: "desc").first
  end

  def previous_published_edition
    series.where(state: "published").order(version_number: "desc").second
  end

  def in_progress_sibling
    subsequent_siblings.in_progress.order(version_number: "desc").first
  end

  def can_create_new_edition?
    subsequent_siblings.in_progress.empty?
  end

  def meta_data
    PublicationMetadata.new self
  end

  def fact_check_email_address
    FactCheckAddress.new.for_edition(self)
  end

  def get_next_version_number
    latest_version = series.order(version_number: "desc").first.version_number
    latest_version + 1
  end

  def indexable_content
    respond_to?(:parts) ? indexable_content_with_parts : indexable_content_without_parts
  end

  def indexable_content_without_parts
    if respond_to?(:body)
      "#{alternative_title} #{Govspeak::Document.new(body).to_text}".strip
    else
      alternative_title
    end
  end

  def indexable_content_with_parts
    content = indexable_content_without_parts
    return content unless published_edition
    parts.inject([content]) { |acc, part|
      acc.concat([part.title, Govspeak::Document.new(part.body).to_text])
    }.compact.join(" ").strip
  end

  # If the new clone is of the same type, we can copy all its fields over; if
  # we are changing the type of the edition, any fields other than the base
  # fields will likely be meaningless.
  def fields_to_copy(edition_class)
    edition_class == self.class ? self.class.fields_to_clone : []
  end

  def build_clone(edition_class=nil)
    unless state == "published"
      raise "Cloning of non published edition not allowed"
    end
    unless can_create_new_edition?
      raise "Cloning of a published edition when an in-progress edition exists
             is not allowed"
    end

    edition_class = self.class unless edition_class
    new_edition = edition_class.new(title: self.title,
                                    version_number: get_next_version_number)

    real_fields_to_merge = fields_to_copy(edition_class) +
                           [:panopticon_id, :overview, :alternative_title,
                            :slug, :section, :department]

    real_fields_to_merge.each do |attr|
      new_edition[attr] = read_attribute(attr)
    end

    if edition_class == AnswerEdition and %w(GuideEdition ProgrammeEdition TransactionEdition).include?(self.class.name)
      new_edition.body = whole_body
    end

    if edition_class == TransactionEdition and %w(AnswerEdition GuideEdition ProgrammeEdition).include?(self.class.name)
      new_edition.more_information = whole_body
    end

    if edition_class == GuideEdition and self.is_a?(AnswerEdition)
      new_edition.parts.build(title: "Part One", body: whole_body,
                              slug: "part-one")
    end

    new_edition
  end

  def self.find_or_create_from_panopticon_data(panopticon_id,
                                               importing_user, api_credentials)
    existing_publication = Edition.where(panopticon_id: panopticon_id)
                                  .order_by([:version_number, :desc]).first
    return existing_publication if existing_publication

    raise "Artefact not found" unless metadata = Artefact.find(panopticon_id)

    importing_user.create_edition(metadata.kind.to_sym,
      panopticon_id: metadata.id,
      slug: metadata.slug,
      title: metadata.name,
      section: metadata.section,
      department: metadata.department,
      business_proposition: metadata.business_proposition)
  end

  def self.find_and_identify(slug, edition)
    scope = where(slug: slug)

    if edition.present? and edition == "latest"
      scope.order_by(:version_number).last
    elsif edition.present?
      scope.where(version_number: edition).first
    else
      scope.where(state: "published").order_by(:created_at).last
    end
  end

  def panopticon_uri
    Plek.current.find("panopticon") + "/artefacts/" + (panopticon_id || slug).to_s
  end

  def format
    self.class.to_s.gsub("Edition", "")
  end

  def format_name
    format
  end

  def has_video?
    false
  end

  def safe_to_preview?
    true
  end

  def has_sibling_in_progress?
    ! sibling_in_progress.nil?
  end

  # Stop broadcasting a delete message unless there are no siblings.
  def broadcast_action(callback_action)
    unless callback_action == "destroyed" and self.siblings.any?
      super(callback_action)
    end
  end

  def was_published
    previous_siblings.all.each(&:archive)
    notify_siblings_of_published_edition
  end

  def update_from_artefact(artefact)
    self.title = artefact.name unless published?
    self.slug = artefact.slug
    self.section = artefact.section
    self.department = artefact.department
    self.business_proposition = artefact.business_proposition
    self.save!
  end

  def check_for_archived_artefact
    if panopticon_id
      a = Artefact.find(panopticon_id)
      if a.state == "archived" and changed_attributes.any?
        # If we're only changing the state to archived, that's ok
        # Any other changes are not allowed
        allowed_keys = ["state", "updated_at"]
        unless ((changed_attributes.keys - allowed_keys).empty?) and state == "archived"
          raise "Editing of an edition with an Archived artefact is not allowed"
        end
      end
    end
  end

  def artefact
    Artefact.find(panopticon_id)
  end

  # When we delete an edition is the only one in its series
  # we delete the associated artefact to remove all trace of the
  # item from the system.
  #
  # We don't do this by notifying panopticon as this will only ever
  # happen for artefacts representing editions that haven't been
  # published (and therefore aren't registered in the rest of the)
  # system.
  def destroy_artefact
    if can_destroy? && siblings.empty?
      Artefact.find(self.panopticon_id).destroy
    end
  end
end
