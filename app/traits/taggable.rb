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

        define_method "#{k.singularize}_ids" do
          tags_of_type(k.singularize).collect(&:tag_id)
        end

        define_method k do
          tags_of_type(k.singularize)
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
    klass.attr_protected :tags, :tag_ids
    klass.__send__       :private, :tag_ids=
  end

  def set_tags_of_type(collection_name, values)
    tag_type = collection_name.singularize

    # Ensure all tags loaded from database. This feels inelegant
    # but ensures integrity. It could go away if we moved to a more
    # consistent repository approach to retrieving and constructing
    # objects
    tags

    new_tags = values.map { |v| TagRepository.load(v) }.compact
    raise "Missing tags" unless new_tags.size == values.size
    raise "Wrong tag type" unless new_tags.all? { |t| t.tag_type == tag_type }

    @tags.reject! { |t| t.tag_type == tag_type }
    @tags += new_tags
  end

  # The primary tag is simply the first one of its
  # type. If that tag is already applied this method
  # moves it to the start of the list. If it's not then
  # we add it at the start of the list.
  def set_primary_tag_of_type(tag_type, value)
    tags

    tag = TagRepository.load(value)
    raise "Missing tag" unless tag
    raise "Wrong tag type" unless tag.tag_type == tag_type

    @tags -= [tag]
    @tags.unshift(tag)
  end

  def tags_of_type(tag_type)
    tags.select { |t| t.tag_type == tag_type }
  end

  def reconcile_tag_ids
    tags

    self.tag_ids = @tags.collect(&:tag_id)
  end

  def tags
    @tags ||= TagRepository.load_all_with_ids(tag_ids).to_a
  end

  def save
    reconcile_tag_ids
    super
  end
end