module Taggable
  module ClassMethods
    def stores_tags_for(*keys)
      tag_types = keys.to_a.flatten.compact.map(&:to_s)
      class_attribute :tag_types
      self.tag_types = tag_types

      tag_types.each do |k|
        define_method "#{k}=" do |values|
          set_tags_of_type(k, values)
        end
        alias_method :"#{k.singularize}_ids=", :"#{k}="

        define_method k do |*args|
          include_draft = args.first
          tags_of_type(k.singularize, include_draft)
        end

        define_method "#{k.singularize}_ids" do |*args|
          send(k, *args).map(&:tag_id)
        end
      end
    end

    def has_primary_tag_for(*keys)
      tag_types = keys.to_a.flatten.compact.map(&:to_s)
      class_attribute :primary_tag_types
      self.primary_tag_types = tag_types

      tag_types.each do |key|
        method_name = "primary_#{key}"

        define_method "#{method_name}=" do |value|
          set_primary_tag_of_type(key.to_s, value)
        end

        define_method method_name do
          tags_of_type(key.to_s).first
        end
      end
    end
  end

  def self.included(klass)
    klass.extend         ClassMethods
    klass.field          :tag_ids, type: Array, default: []
    klass.field          :tags, type: Array, default: []

    klass.index          :tag_ids
    klass.attr_protected :tags, :tag_ids
    klass.__send__       :private, :tag_ids=
  end

  def set_tags_of_type(collection_name, tag_ids)
    tag_type = collection_name.singularize
    tag_ids = Array(tag_ids)

    Tag.validate_tag_ids(tag_ids, tag_type)

    current_tags = attributes['tags'].reject {|t| t[:tag_type] == tag_type }

    self.tags = current_tags + tag_ids.map {|tag_id|
      {tag_id: tag_id, tag_type: tag_type}
    }
  end

  # The primary tag is simply the first one of its
  # type. If that tag is already applied this method
  # moves it to the start of the list. If it's not then
  # we add it at the start of the list.
  def set_primary_tag_of_type(tag_type, tag_id)
    Tag.validate_tag_ids([tag_id], tag_type)

    tag_tuple = {tag_id: tag_id, tag_type: tag_type}

    current_tags = attributes['tags'].dup
    current_tags.delete(tag_tuple)

    self.tags = current_tags.unshift(tag_tuple)
  end

  def tags_of_type(tag_type, include_draft = false)
    tags(include_draft).select { |t| t.tag_type == tag_type }
  end

  def tags=(new_tag_tuples)
    self.tag_ids = new_tag_tuples.map {|tuple| tuple[:tag_id] }
    super(new_tag_tuples)
  end

  def tags(include_draft = false)
    all_tags = Tag.by_tag_ids(tag_ids)

    if include_draft
      all_tags
    else
      all_tags.reject {|tag| tag.state == 'draft' }
    end
  end
end
