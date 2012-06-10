module Taggable
  module ClassMethods
    def stores_tags_for(*keys)
      keys.map!(&:to_s)

      keys.each { |k| 
        attr_accessor k

        # define_method "#{k.singularize}=" do |values|
        #   # tag_ids.clear
        #   # tags.clear

        #   values.each do |value|
        #     tag_id, tag = Tag.id_and_entity(value)

        #     tag_ids.push(tag_id) unless tag_ids.include?(tag_id)
        #     tags.push(tag_id) unless tags.include?(tag)
        #   end
        # end

        # define_method "#{k.singularize}_ids" do
        #   tags.select { |t| t.tag_type == k.singularize }.collect(&:tag_id)
        # end

        # define_method k do
        #   tags.select { |t| t.tag_type == k.singularize }
        # end
      }
      self.tag_keys = keys
    end

    def has_primary_tag_for(key)
      raise "Only one primary tag type allowed" unless key.is_a?(Symbol)

      method_name = "primary_#{key.to_s.singularize}"
      attr_accessor method_name
      # define_method "#{method_name}=" do |value|
      #   tag_id, tag = Tag.id_and_entity(value)

      #   tag_ids.delete(tag_id)
      #   tag_ids.unshift(tag_id)

      #   tags.delete(tag)
      #   tags.unshift(tag)
      # end

      # define_method method_name do
      #   __send__(key.to_s.pluralize).first
      # end
    end
  end

  def self.included(klass)
    klass.extend         ClassMethods
    klass.field          :tag_ids, type: Array, default: []
    klass.attr_protected :tags, :tag_ids
    klass.cattr_accessor :tag_keys, :primary_tag_keys
  end

  def reconcile_tags
  end

  # def expand_tags
  #   # Process types of tags and drop into appropriate places
  # end

  def reconcile_tags
    general_tags = []
    special_tags = []

    self.class.tag_keys.each do |key|
      general_tags += __send__(key).to_a
    end

    self.class.primary_tag_keys.each do |key|
      special_tags << __send__("primary_#{key.to_s.singularize}")
    end

    # Don't duplicate tags
    general_tags -= special_tags

    # Fill up tag_ids
    self.tag_ids = (special_tags + general_tags).reject { |t| t.blank? }
  end

  # TODO: Work out best way to memoise this
  def tags
    TagRepository.load_all_with_ids(tag_ids).to_a
  end

  def save
    reconcile_tags
    parent
  end
end