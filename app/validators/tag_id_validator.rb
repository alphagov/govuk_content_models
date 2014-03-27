class TagIdValidator < ActiveModel::Validator

  def validate(record)
    unless valid_tag_id?(record.tag_id)
      record.errors[:tag_id] << "ID must be valid in a URL and have no more than one slash"
    end
  end

  private

  def valid_tag_id?(tag_id)
    tag_id.to_s.match(/\A[a-z0-9\-\/]+\Z/) && tag_id.to_s.count('/') <= 1
  end

end
