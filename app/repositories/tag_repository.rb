require "tag"
models_folder = File.expand_path("../models", File.dirname(__FILE__))

Dir.glob(File.join(models_folder, "*_tag.rb")).each do |f|
  require f
end

module TagRepository

  # If tag_type parameter is given, load all tags of that type.
  def self.load_all(options={})
    tag_type = options[:tag_type]
    if tag_type.nil?
      Tag.all
    else
      Tag.where(:tag_type => tag_type)
    end
  end

  def self.load(id)
    tag = Tag.where(tag_id: id).first
    correct_tag_class(tag)
    # tag
  end

  def self.tag_class_exists?(class_name)
    klass = Module.const_get(class_name)
    return klass.is_a?(Class)
  rescue NameError
    return false
  end

  def self.correct_tag_class(tag)
    class_name = tag.tag_type.camelize + "Tag"

    if tag_class_exists?(class_name)
      tag.becomes(class_name.constantize)
    else
      tag
    end
  end

  def self.put(tag)
    t = Tag.where(tag_id: tag[:tag_id]).first
    unless t
      Tag.create! tag
    else
      t.update_attributes! tag
    end
  end
end
