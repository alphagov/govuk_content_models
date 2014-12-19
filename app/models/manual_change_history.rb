require "prerendered_entity"

class ManualChangeHistory
  include Mongoid::Document
  include Mongoid::Timestamps
  extend PrerenderedEntity

  field :updates, type: Array
  field :slug, type: String
  field :manual_slug, type: String

  index "slug", unique: true

  validates :slug, uniqueness: true
end
