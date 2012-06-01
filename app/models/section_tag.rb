require "tag"

class SectionTag < Tag
  @@tag_type = "section"

  field :description, type: String
  field :parent_id, type: String

  validates :tag_type, inclusion: { in: [@@tag_type] }

  def initialize(attrs={}, options={})
    super({tag_type: @@tag_type}.merge(attrs), options)
  end

  def as_json(options={})
    super.merge(
        description: self.description,
        parent_id: self.parent_id
    )
  end

  def parent
    TagRepository.load parent_id if parent_id
  end

end
