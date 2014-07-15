require "answer_edition"
require "guide_edition"
require "local_transaction_edition"
require "place_edition"
require "programme_edition"
require "transaction_edition"

module WorkflowActor
  SIMPLE_WORKFLOW_ACTIONS = %w(
    request_review
    request_amendments
    approve_review
    approve_fact_check
    archive
    cancel_scheduled_publishing
  )

  def record_action(edition, type, options={})
    type = Action.const_get(type.to_s.upcase)
    action = edition.new_action(self, type, options)
    edition.denormalise_users!
    action
  end

  def record_action_without_validation(edition, type, options={})
    type = Action.const_get(type.to_s.upcase)
    action = edition.new_action_without_validation(self, type, options)
    edition.denormalise_users!
    action
  end

  def can_take_action(action, edition)
    respond_to?(:"can_#{action}?") ? __send__(:"can_#{action}?", edition) : true
  end

  def take_action(edition, action, details = {}, action_parameters = [])
    if can_take_action(action, edition) && edition.send(action, *action_parameters)
      record_action(edition, action, details)
      edition
    else
      false
    end
  end

  def take_action!(edition, action, details = {}, action_parameters = [])
    edition = take_action(edition, action, details, action_parameters)
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

    take_action(edition, __method__, details)
  end

  # Always records the action.
  def receive_fact_check(edition, details)
    edition.perform_event_without_validations(:receive_fact_check)
    # Fact checks are processed async, so the user doesn't get an opportunity
    # to retry without the content that (inadvertantly) fails validation, which happens frequently.
    record_action_without_validation(edition, :receive_fact_check, details)
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

  def schedule_for_publishing(edition, details)
    publish_at = details.delete(:publish_at)
    take_action(edition, __method__, details, [publish_at])
  end

  def publish(edition, details)
    if edition.published_edition
      details.merge!({ diff: edition.edition_changes })
    end

    take_action(edition, __method__, details)
  end

  def can_approve_review?(edition)
    requester_different?(edition)
  end

  def can_request_amendments?(edition)
    if edition.in_review?
      requester_different?(edition)
    else
      true
    end
  end

  def assign(edition, recipient)
    edition.set(:assigned_to_id, recipient.id)
    record_action edition.reload, __method__, recipient: recipient
  end

  private

  def requester_different?(edition)
    # To accommodate latest_status_action being nil, we'll always return true in
    # those cases
    # This is intended as a v.temporary fix until we can remedy the root cause
    if edition.latest_status_action
      edition.latest_status_action.requester_id != self.id
    else
      true
    end
  end
end
