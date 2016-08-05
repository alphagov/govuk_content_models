require "csv"
require "safe_html"

class LocalAuthority
  include Mongoid::Document

  field :name,               type: String
  field :snac,               type: String
  field :local_directgov_id, type: Integer
  field :tier,               type: String
  field :homepage_url,       type: String

  validates_uniqueness_of :snac
  validates_presence_of   :snac, :local_directgov_id, :name, :tier

  scope :for_snacs, ->(snacs) { any_in(snac: snacs) }

  def self.find_by_snac(snac)
    for_snacs([snac]).first
  end

end
