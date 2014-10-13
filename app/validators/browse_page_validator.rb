class BrowsePageValidator < ActiveModel::Validator
  def validate(record)
    if (browse_pages = record.browse_pages)
      if browse_pages.uniq.count < browse_pages.count
        record.errors.add(:browse_pages, "can't have duplicates")
      end
    end
  end
end
