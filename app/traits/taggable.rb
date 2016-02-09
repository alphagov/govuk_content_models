module Taggable
  module ClassMethods
    def stores_tags_for(*tag_types)
      tag_types = tag_types.map {|tag_type|
        raise ArgumentError.new("Please provide tag types as symbols") unless tag_type.is_a?(Symbol)
        tag_type.to_s
      }

      class_attribute :tag_types
      self.tag_types = tag_types

      tag_types.each do |tag_type|
        define_method("#{tag_type}=") do |tag_ids|
          set_tags_of_type(tag_type, tag_ids)
        end
        alias_method :"#{tag_type.singularize}_ids=", :"#{tag_type}="

        define_method(tag_type) do |*args|
          include_draft = args.first
          tags_of_type(tag_type.singularize, include_draft)
        end

        define_method("#{tag_type.singularize}_ids") do |*args|
          send(tag_type, *args).map(&:tag_id)
        end
      end
    end

    def has_primary_tag_for(*tag_types)
      tag_types = tag_types.map {|tag_type|
        raise ArgumentError.new("Please provide tag types as symbols") unless tag_type.is_a?(Symbol)
        tag_type.to_s
      }

      class_attribute :primary_tag_types
      self.primary_tag_types = tag_types

      tag_types.each do |tag_type|
        define_method("primary_#{tag_type}=") do |tag_id|
          set_primary_tag_of_type(tag_type, tag_id)
        end

        define_method("primary_#{tag_type}") do
          tags_of_type(tag_type).first
        end
      end
    end
  end

  def self.included(klass)
    klass.extend         ClassMethods
    klass.field          :tag_ids, type: Array, default: []
    klass.field          :tags, type: Array, default: []

    klass.index          tag_ids: 1
    klass.__send__       :private, :tag_ids=
  end

  def set_tags_of_type(collection_name, tag_ids)
    tag_type = collection_name.singularize
    tag_ids = Array(tag_ids)

    Tag.validate_tag_ids(tag_ids, tag_type)

    current_tags = attributes['tags'].reject {|t| t['tag_type'] == tag_type }

    self.tags = current_tags + tag_ids.map {|tag_id|
      {'tag_id' => tag_id, 'tag_type' => tag_type}
    }
  end

  # The primary tag is simply the first one of its
  # type. If that tag is already applied this method
  # moves it to the start of the list. If it's not then
  # we add it at the start of the list.
  def set_primary_tag_of_type(tag_type, tag_id)
    Tag.validate_tag_ids([tag_id], tag_type)

    tag_tuple = {'tag_id' => tag_id, 'tag_type' => tag_type}

    current_tags = attributes['tags'].dup
    current_tags.delete(tag_tuple)

    self.tags = current_tags.unshift(tag_tuple)
  end

  def tags_of_type(tag_type, include_draft = false)
    tags(include_draft).select { |t| t.tag_type == tag_type }
  end

  def tags=(new_tag_tuples)
    self.tag_ids = new_tag_tuples.map {|tuple| tuple['tag_id'] }
    super(new_tag_tuples)
  end

  def tags(include_draft = false)
    Tag.by_tag_ids(tag_ids, draft: include_draft)
  end
end
