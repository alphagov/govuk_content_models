class Tag
  include Mongoid::Document
  field :tag_id,   type: String
  field :title,    type: String
  field :tag_type, type: String #TODO: list of accepted types?

  field :parent_id, type: String

  index :tag_id, unique: true
  index :tag_type

  validates_presence_of :tag_id, :title, :tag_type

  def as_json(options = {})
    {
      id: self.tag_id,
      title: self.title,
      type: self.tag_type
    }
  end

  def has_parent?
    parent_id.present?
  end

  def parent
    if has_parent?
      TagRepository.load(parent_id).first
    end
  end

  def self.id_and_entity(value)
    if value.is_a?(Tag)
      return value.name, value
    else
      return value, TagRepository.load(value)
    end
  end
end
