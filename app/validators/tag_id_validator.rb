class TagIdValidator < ActiveModel::Validator

  def validate(record)
    unless valid_tag_id?(record)
      record.errors[:tag_id] << "ID must be valid in a URL and have no more than one slash"
    end
  end

private

  def valid_tag_id?(tag)
    tag_contains_correct_characters(tag.tag_id) &&
    tag_doesnt_end_with_slash(tag.tag_id) &&
    tag_contains_correct_number_of_slashes(tag.tag_id, child?: tag_is_child_tag?(tag))
  end

  def tag_contains_correct_characters(tag_id)
    tag_id =~ %r{^[a-z0-9/-]+$}
  end

  def tag_doesnt_end_with_slash(tag_id)
    !tag_id.end_with?('/')
  end

  def tag_contains_correct_number_of_slashes(tag_id, options = {})
    if options[:child?]
      tag_id.count('/') <= 1
    else
      tag_id.count('/') == 0
    end
  end

  def tag_is_child_tag?(tag)
    tag.respond_to?(:parent_id) && tag.parent_id.present?
  end

end
