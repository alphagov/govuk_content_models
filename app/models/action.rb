require "safe_html"

class Action
  include Mongoid::Document

  STATUS_ACTIONS = [
    CREATE              = "create",
    START_WORK          = "start_work",
    REQUEST_REVIEW      = "request_review",
    APPROVE_REVIEW      = "approve_review",
    APPROVE_FACT_CHECK  = "approve_fact_check",
    REQUEST_AMENDMENTS  = "request_amendments",
    SEND_FACT_CHECK     = "send_fact_check",
    RECEIVE_FACT_CHECK  = "receive_fact_check",
    SKIP_FACT_CHECK     = "skip_fact_check",
    PUBLISH             = "publish",
    ARCHIVE             = "archive",
    NEW_VERSION         = "new_version",
  ]

  NON_STATUS_ACTIONS = [
    NOTE                 = "note",
    ASSIGN               = "assign",
  ]

  embedded_in :edition
  belongs_to :recipient, class_name: "User"
  belongs_to :requester, class_name: "User"

  field :approver_id,        type: Integer
  field :approved,           type: DateTime
  field :comment,            type: String
  field :diff,               type: String
  field :request_type,       type: String
  field :email_addresses,    type: String
  field :customised_message, type: String
  field :created_at,         type: DateTime, default: lambda { Time.now }

  validates_with SafeHtml

  def container_class_name(edition)
    edition.container.class.name.underscore.humanize
  end

  def status_action?
    STATUS_ACTIONS.include?(request_type)
  end

  def to_s
    request_type.humanize.capitalize
  end

  def is_fact_check_request?
    # SEND_FACT_CHECK is now a state - in older publications it isn't
    request_type == SEND_FACT_CHECK || request_type == "fact_check_requested" ? true : false
  end
end
