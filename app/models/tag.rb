class Tag
  include Mongoid::Document
  field :tag_id,   type: String
  field :title,    type: String
  field :tag_type, type: String #TODO: list of accepted types?
  field :description, type: String

  field :parent_id, type: String

  index :tag_id, unique: true
  index :tag_type

  validates_presence_of :tag_id, :title, :tag_type

  # This doesn't get set automatically: the code that loads tags
  # should go through them and set this attribute manually
  attr_accessor :uniquely_named

  def as_json(options = {})
    {
      id: self.tag_id,
      title: self.title,
      type: self.tag_type,
      description: self.description
    }
  end

  def has_parent?
    parent_id.present?
  end

  def parent
    if has_parent?
      TagRepository.load(parent_id)
    end
  end

  def self.id_and_entity(value)
    if value.is_a?(Tag)
      return value.name, value
    else
      return value, TagRepository.load(value)
    end
  end

  def unique_title
    self.uniquely_named ? self.title : "#{self.title} [#{self.tag_id}]"
  end

  def to_s
    title
  end
end
