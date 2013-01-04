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

        define_method k do
          tags_of_type(k.singularize)
        end
        define_method "#{k.singularize}_ids" do
          tags_of_type(k.singularize).collect(&:tag_id)
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
    klass.index          :tag_ids
    klass.attr_protected :tags, :tag_ids
    klass.__send__       :private, :tag_ids=
  end

  def set_tags_of_type(collection_name, values)
    tag_type = collection_name.singularize

    # Ensure all tags loaded from database. This feels inelegant
    # but ensures integrity. It could go away if we moved to a more
    # consistent repository approach to retrieving and constructing
    # objects, or if we used a custom serialization type for tags
    # as documented on http://mongoid.org/en/mongoid/docs/documents.html
    tags

    # This will raise a Tag::MissingTags exception unless all the tags exist
    new_tags = Tag.by_tag_ids!(values, tag_type)

    @tags.reject! { |t| t.tag_type == tag_type }
    @tags += new_tags
  end

  # The primary tag is simply the first one of its
  # type. If that tag is already applied this method
  # moves it to the start of the list. If it's not then
  # we add it at the start of the list.
  def set_primary_tag_of_type(tag_type, value)
    tags

    tag = Tag.by_tag_id(value, tag_type)
    raise "Missing tag" unless tag
    raise "Wrong tag type" unless tag.tag_type == tag_type

    @tags -= [tag]
    @tags.unshift(tag)
  end

  def tags_of_type(tag_type)
    tags.select { |t| t.tag_type == tag_type }
  end

  def reconcile_tag_ids
    # Ensure tags are loaded so we don't accidentally
    # remove all tagging in situations where tags haven't
    # been accessed during the lifetime of the object
    tags

    self.tag_ids = @tags.collect(&:tag_id)
  end

  def tags
    @tags ||= load_all_tags_with_ids(tag_ids).to_a
  end

  def reload
    @tags = nil
    super
  end

  def save(options={})
    reconcile_tag_ids
    super(options)
  end

  def save!(options={})
    reconcile_tag_ids
    super(options)
  end

  def load_all_tags_with_ids(ids)
    Tag.any_in(tag_id: ids).to_a.sort_by! { |tag| ids.index(tag.tag_id) }
  end
end
