require "prerendered_entity"

class RenderedSpecialistDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  extend PrerenderedEntity

  field :slug,                   type: String
  field :title,                  type: String
  field :summary,                type: String
  field :body,                   type: String

  field :details,                type: Hash

  index "slug", unique: true

  GOVSPEAK_FIELDS = []

  validates :slug, uniqueness: true
  validates_with SafeHtml
end
