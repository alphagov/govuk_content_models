require "prerendered_entity"

class RenderedManual
  include Mongoid::Document
  include Mongoid::Timestamps
  extend PrerenderedEntity

  field :manual_id, type: String
  field :slug, type: String
  field :title, type: String
  field :summary, type: String
  field :section_groups, type: Array

  index "slug", unique: true

  GOVSPEAK_FIELDS = []

  validates_with SafeHtml
  validates_uniqueness_of :slug
end
