require "digest/md5"
require "cgi"
require "gds-sso/user"
require "workflow_actor"

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include GDS::SSO::User
  include WorkflowActor

  field "name",    type: String
  field "uid",     type: String
  field "version", type: Integer
  field "email",   type: String

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :name, :uid, :version

  scope :alphabetized, order_by(name: :asc)

  # GDS::SSO specifically looks for find_by_uid within warden
  # when loading authentication user from session
  def self.find_by_uid(uid)
    where(uid: uid).first
  end

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
end
