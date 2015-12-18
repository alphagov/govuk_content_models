require "digest/md5"
require "cgi"
require "gds-sso/user"
require "safe_html"

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include GDS::SSO::User

  # Let an app configure the collection name to use, e.g. set a constant in an
  # initializer
  def self.collection_name
    defined?(USER_COLLECTION_NAME) ? USER_COLLECTION_NAME : "users"
  end

  field "name",                    type: String
  field "uid",                     type: String
  field "version",                 type: Integer
  field "email",                   type: String
  field "permissions",             type: Array
  field "remotely_signed_out",     type: Boolean, default: false
  field "organisation_slug",       type: String
  field "disabled",                type: Boolean, default: false
  field "organisation_content_id", type: String

  index "uid", unique: true
  index "disabled"

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :name, :uid
  attr_accessible :email, :name, :uid, :permissions, as: :oauth

  scope :alphabetized, order_by(name: :asc)
  scope :enabled, any_of({ :disabled.exists => false },
                         { :disabled.in => [false, nil] })

  def to_s
    name || email || ""
  end

  def gravatar_url(opts = {})
    opts.symbolize_keys!
    "%s.gravatar.com/avatar/%s%s" % [
      opts[:ssl] ? "https://secure" : "http://www",
      Digest::MD5.hexdigest(email.downcase),
      opts[:s] ? "?s=#{CGI.escape(opts[:s])}" : ""
    ]
  end

  def progress(edition, action_attributes)
    request_type = action_attributes.delete(:request_type)

    processor = GovukContentModels::ActionProcessors::REQUEST_TYPE_TO_PROCESSOR[request_type.to_sym]
    edition = GovukContentModels::ActionProcessors::const_get(processor).new(self, edition, action_attributes, {}).processed_edition
    edition.save if edition
  end

  def record_note(edition, comment, type = Action::NOTE)
    edition.new_action(self, type, comment: comment)
  end

  def resolve_important_note(edition)
    record_note(edition, nil, Action::IMPORTANT_NOTE_RESOLVED)
  end

  def create_edition(format, attributes = {})
    GovukContentModels::ActionProcessors::CreateEditionProcessor.new(self, nil, {}, { format: format, edition_attributes: attributes }).processed_edition
  end

  def new_version(edition, convert_to = nil)
    GovukContentModels::ActionProcessors::NewVersionProcessor.new(self, edition, {}, { convert_to: convert_to }).processed_edition
  end

  def assign(edition, recipient)
    GovukContentModels::ActionProcessors::AssignProcessor.new(self, edition, { recipient_id: recipient.id }).processed_edition
  end

  def unassign(edition)
    GovukContentModels::ActionProcessors::AssignProcessor.new(self, edition).processed_edition
  end
end
