require "answer_edition"
require "guide_edition"
require "local_transaction_edition"
require "place_edition"
require "programme_edition"
require "transaction_edition"

module WorkflowActor
  SIMPLE_WORKFLOW_ACTIONS = %W[start_work request_review
    request_amendments approve_review approve_fact_check]

  def record_action(edition, type, options={})
    type = Action.const_get(type.to_s.upcase)
    action = edition.new_action(self, type, options)
    edition.save! # force callbacks for denormalisation
    action
  end

  def take_action(edition, action, details = {})
    apply_guards = respond_to?(:"can_#{action}?") ? __send__(:"can_#{action}?", edition) : true

    if apply_guards and transition = edition.send(action)
      record_action(edition, action, details)
      edition
    else
      false
    end
  end

  def take_action!(edition, action, details = {})
    edition = take_action(edition, action, details)
    edition.save if edition
  end

  def progress(edition, activity_details)
    activity = activity_details.delete(:request_type)

    edition = send(activity, edition, activity_details)
    edition.save if edition
  end

  def record_note(edition, comment)
    edition.new_action(self, "note", comment: comment)
  end

  def create_edition(format, attributes = {})
    format = "#{format}_edition" unless format.to_s.match(/edition$/)
    publication_class = format.to_s.camelize.constantize

    item = publication_class.create(attributes)
    record_action(item, Action::CREATE) if item.persisted?
    item
  end

  def new_version(edition, convert_to = nil)
    return false unless edition.published?

    if not convert_to.nil?
      convert_to = convert_to.to_s.camelize.constantize
      new_edition = edition.build_clone(convert_to)
    else
      new_edition = edition.build_clone
    end

    if new_edition
      record_action new_edition, Action::NEW_VERSION
      new_edition
    else
      false
    end
  end

  def send_fact_check(edition, details)
    return false if details[:email_addresses].blank?

    details[:comment] ||= "Fact check requested"
    details[:comment] += "\n\nResponses should be sent to: " + edition.fact_check_email_address

    take_action(edition, __method__, details)
  end

  # Advances state if possible (i.e. if in "fact_check" state)
  # Always records the action.
  def receive_fact_check(edition, details)
    edition.receive_fact_check
    record_action(edition, :receive_fact_check, details)
  end

  def skip_fact_check(edition, details)
    edition.skip_fact_check
    record_action(edition, :skip_fact_check, details)
  end

  SIMPLE_WORKFLOW_ACTIONS.each do |method|
    define_method(method) do |edition, details = {}|
      take_action(edition, __method__, details)
    end
  end

  def publish(edition, details)
    details.merge!({ diff: edition.edition_changes }) if edition.published_edition

    take_action(edition, __method__, details)
  end

  def can_approve_review?(edition)
    edition.latest_status_action.requester_id != self.id
  end
  alias :can_request_amendments? :can_approve_review?

  def assign(edition, recipient)
    edition.assigned_to_id = recipient.id

    # We're saving the edition here as the controller treats assignment as a special case.
    # The controller saves the publication, then updates assignment.
    edition.save! and edition.reload
    record_action edition, __method__, recipient: recipient
  end
end
