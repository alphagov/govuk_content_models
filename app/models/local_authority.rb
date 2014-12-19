require "csv"
require "local_interaction"
require "safe_html"

class LocalAuthority
  include Mongoid::Document

  embeds_many :local_interactions

  field :name,               type: String
  field :snac,               type: String
  field :local_directgov_id, type: Integer
  field :tier,               type: String
  field :contact_address,    type: Array
  field :contact_url,        type: String
  field :contact_phone,      type: String
  field :contact_email,      type: String

  validates_uniqueness_of :snac
  validates_presence_of   :snac, :local_directgov_id, :name, :tier

  scope :for_snacs, ->(snacs) { any_in(snac: snacs) }

  def self.find_by_snac(snac)
    for_snacs([snac]).first
  end

  def provides_service?(lgsl_code, lgil_code = nil)
    interactions_for(lgsl_code, lgil_code).any?
  end

  def interactions_for(lgsl_code, lgil_code = nil)
    interactions = local_interactions.where(lgsl_code: lgsl_code)
    if lgil_code
      interactions.where(lgil_code: lgil_code)
    else
      interactions
    end
  end

  def preferred_interaction_for(lgsl_code, lgil_code = nil)
    interactions = local_interactions.where(lgsl_code: lgsl_code)
    if lgil_code
      interactions.where(lgil_code: lgil_code).first
    else
      interactions.excludes(
        lgil_code: LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION
      ).order_by([:lgil_code, :asc]).first ||
      interactions.where(
        lgil_code: LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION
      ).first
    end
  end

end
