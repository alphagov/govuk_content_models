class TagIdValidator < ActiveModel::Validator

  def validate(record)
    if record.parent_id.present?
      valid = valid_tag_id_with_parent?(record.tag_id, record.parent_id)
    else
      valid = valid_tag_id?(record.tag_id)
    end

    unless valid
      record.errors[:tag_id] << "ID must be valid in a URL and match the tag hierarchy"
    end
  end

  private

  def valid_tag_id?(tag_id)
    tag_id.to_s.match(/\A[a-z0-9\-]+\Z/)
  end

  def valid_tag_id_with_parent?(tag_id, parent_id)
    tag_id.match(/\A#{parent_id}\/[a-z0-9\-]+\Z/)
  end

end
