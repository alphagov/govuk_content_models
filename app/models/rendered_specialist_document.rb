class RenderedSpecialistDocument
  include Mongoid::Document
  include Mongoid::Timestamps

  field :document_id,            type: String
  field :slug,                   type: String
  field :title,                  type: String
  field :summary,                type: String
  field :body,                   type: String
  field :opened_date,            type: Date
  field :closed_date,            type: Date
  field :case_type,              type: String
  field :case_type_label,        type: String
  field :case_state,             type: String
  field :case_state_label,       type: String
  field :market_sector,          type: String
  field :market_sector_label,    type: String
  field :outcome_type,           type: String
  field :outcome_type_label,     type: String
  field :headers,                type: Array

  index "slug", unique: true

  GOVSPEAK_FIELDS = []

  validates :slug, uniqueness: true
  validates_with SafeHtml

  def self.create_or_update_by_slug!(attributes)
    RenderedSpecialistDocument.find_or_initialize_by(
      slug: attributes.fetch(:slug)
    ).tap do |doc|
      doc.update_attributes!(attributes)
    end
  end

  def self.find_by_slug(slug)
    where(slug: slug).first
  end
end
