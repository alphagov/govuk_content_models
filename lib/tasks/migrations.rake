namespace :migrations do
  desc "Switch from a hacky parent/child relationship to an explicit one"
  task :explicit_parent_id do
    Tag.load_all.each do |tag|
      if tag.is_a?(SectionTag) and tag.tag_id.include? '/'
        tag.update_attributes(
          parent_id: tag_id.split('/').first
        )
      end
    end
  end
end