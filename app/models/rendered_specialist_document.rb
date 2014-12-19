require "prerendered_entity"

class RenderedSpecialistDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  extend PrerenderedEntity

  field :slug,                   type: String
  field :title,                  type: String
  field :summary,                type: String
  field :body,                   type: String
  field :published_at,           type: DateTime

  field :details,                type: Hash

  index "slug", unique: true

  validates :slug, uniqueness: true
end
