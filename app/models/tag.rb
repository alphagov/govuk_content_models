require "safe_html"
require 'tag_id_validator'
require 'state_machines-mongoid'

class Tag
  include Mongoid::Document

  field :tag_id,            type: String
  field :title,             type: String
  field :tag_type,          type: String #TODO: list of accepted types?
  field :description,       type: String
  field :short_description, type: String
  field :parent_id,         type: String
  field :state,             type: String, default: 'draft'
  field :content_id,        type: String

  STATES = ['draft', 'live']

  index tag_id: 1
  index({tag_id: 1, tag_type: 1}, unique: true)
  index tag_type: 1

  validates_presence_of :tag_id, :title, :tag_type
  validates_uniqueness_of :tag_id, scope: :tag_type
  validates_with TagIdValidator

  validates :state, inclusion: { in: STATES }

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

  state_machine initial: :draft do
    event :publish do
      transition draft: :live
    end
  end

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
    Tag.by_tag_id(parent_id, type: self.tag_type, draft: true) if has_parent?
  end

  def unique_title
    self.uniquely_named ? self.title : "#{self.title} [#{self.tag_id}]"
  end

  def to_s
    title
  end

  def self.by_tag_id(tag_id, tag_type_or_options = nil)
    by_tag_ids([tag_id], tag_type_or_options).first
  end

  def self.by_tag_ids(tag_id_list, tag_type_or_options = nil)
    if tag_type_or_options.is_a?(String)
      # Providing the type as a string argument is deprecated in favour of providing the type as an option
      options = {type: tag_type_or_options}
    else
      options = tag_type_or_options || {}
    end

    tag_scope = options[:type] ? Tag.where(tag_type: options[:type]) : Tag

    unless options[:draft]
      tag_scope = tag_scope.where(:state.ne => 'draft')
    end

    tag_scope = tag_scope.any_in(tag_id: tag_id_list)

    # Sort by id list because MongoID 2.x doesn't preserve order
    tags_by_id = tag_scope.each_with_object({}) do |tag, hash|
      hash[tag.tag_id] = tag
    end
    tag_id_list.map { |tag_id| tags_by_id[tag_id] }.compact
  end

  def self.by_tag_types_and_ids(tag_types_and_ids)
    list = tag_types_and_ids.map {|hash| hash.slice(:tag_id, :tag_type) }
    any_of(list)
  end

  # Validate a list of tags by tag ID. Any missing tags raise an exception.
  # Draft tags are considered present for internal validation.
  def self.validate_tag_ids(tag_id_list, tag_type = nil)
    found_tags = by_tag_ids(tag_id_list, type: tag_type, draft: true)
    missing_tag_ids = tag_id_list - found_tags.map(&:tag_id)
    raise MissingTags.new(missing_tag_ids) if missing_tag_ids.any?
  end
end
