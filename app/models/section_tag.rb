class SectionTag < Tag
  field :parent_id, type: String
  field :description, type: String

  def parent
    if self.parent_id.present?
      return TagRepository.load(self.parent_id)
    end
  end
end