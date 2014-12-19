require "csv"
require "safe_html"

class LocalInteraction
  include Mongoid::Document

  LGIL_CODE_PROVIDING_INFORMATION = 8

  field :lgsl_code, type: Integer
  field :lgil_code, type: Integer
  field :url,       type: String

  embedded_in :local_authority

  validates_presence_of :url, :lgil_code, :lgsl_code
  validates_uniqueness_of :lgil_code, :scope => :lgsl_code
end
