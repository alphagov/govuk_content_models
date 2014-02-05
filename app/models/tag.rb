require "safe_html"

class Tag
  include Mongoid::Document
  field :tag_id,   type: String
  field :title,    type: String
  field :tag_type, type: String #TODO: list of accepted types?
  field :description, type: String
  field :short_description, type: String

  field :parent_id, type: String

  GOVSPEAK_FIELDS = []

  index :tag_id
  index [ [:tag_id, Mongo::ASCENDING], [:tag_type, Mongo::ASCENDING] ], unique: true
  index :tag_type

  validates_presence_of :tag_id, :title, :tag_type
  validates_with SafeHtml

  class MissingTags < RuntimeError
    attr_reader :tag_ids

    def initialize(tag_ids)
      super("Missing tags: #{tag_ids.join(", ")}")
      @tag_ids = tag_ids
    end
  end

  # This doesn't get set automatically: the code that loads tags
  # should go through them and set this attribute manually
  attr_accessor :uniquely_named

  def as_json(options = {})
    {
      id: self.tag_id,
      title: self.title,
      type: self.tag_type,
      description: self.description,
      short_description: self.short_description
    }
  end

  def has_parent?
    parent_id.present?
  end

  def parent
    Tag.by_tag_id(parent_id, self.tag_type) if has_parent?
  end

  def unique_title
    self.uniquely_named ? self.title : "#{self.title} [#{self.tag_id}]"
  end

  def to_s
    title
  end

  def self.by_tag_id(tag_id, tag_type = nil)
    scope = tag_type ? Tag.where(tag_type: tag_type) : Tag
    scope.where(tag_id: tag_id).first
  end

  # Retrieve a list of tags by tag ID. Any missing tags become `nil`.
  def self.by_tag_ids(tag_id_list, tag_type = nil)
    scope = tag_type ? Tag.where(tag_type: tag_type) : Tag

    # Load up all the tags in a single query
    tags = scope.any_in(tag_id: tag_id_list).to_a
    tag_id_list.map { |tag_id| tags.find { |t| t.tag_id == tag_id } }
  end

  def self.by_tag_types_and_ids(tag_types_and_ids)
    list = tag_types_and_ids.map {|hash| hash.slice(:tag_id, :tag_type) }
    any_of(list)
  end

  # Retrieve a list of tags by tag ID. Any missing tags raise an exception.
  def self.by_tag_ids!(tag_id_list, tag_type = nil)
    tags = by_tag_ids(tag_id_list, tag_type)
    if tags.any?(&:nil?)
      # Find the tag IDs for which the resulting tag is nil
      missing_ids = tag_id_list.zip(tags).select { |tag_id, tag|
        tag.nil?
      }.map(&:first)
      raise MissingTags, missing_ids
    else
      tags
    end
  end
end
