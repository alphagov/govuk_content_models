class RenderedSpecialistDocument
  include Mongoid::Document

  field :slug,          type: String
  field :title,         type: String
  field :summary,       type: String
  field :body,          type: String
  field :opened_date,   type: Date
  field :closed_date,   type: Date
  field :case_type,     type: String
  field :case_state,    type: String
  field :market_sector, type: String
  field :outcome_type,  type: String
  field :headers,       type: Array

  index "slug", unique: true

  GOVSPEAK_FIELDS = []

  validates :slug, uniqueness: true
  validates_with SafeHtml
end
