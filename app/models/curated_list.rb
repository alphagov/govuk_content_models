require "slug_validator"
require "traits/taggable"

class CuratedList
  include Mongoid::Document
  include Mongoid::Timestamps

  include Taggable
  stores_tags_for :sections

  field "slug", type: String
  field "artefact_ids", type: Array, default: [] # order is important

  index "slug"

  GOVSPEAK_FIELDS = []

  validates :slug, presence: true, uniqueness: true, slug: true
  validates_with SafeHtml

  def self.find_by_slug(slug)
    where(slug: slug).first
  end

  # Returns the artefacts in order, skipping missing artefacts
  def artefacts
    Artefact.where(:_id.in => artefact_ids).sort_by do |artefact|
      artefact_ids.index(artefact.id)
    end
  end
end
