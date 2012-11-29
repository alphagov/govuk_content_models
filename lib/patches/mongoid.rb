require 'mongoid/factory'
require 'mongoid/document'

# Mongoid implements a Single Table Inheritance like mechanism by looking
# at the _type field. Unlike ActiveRecord that field name isn't ordinarily
# overridable on a per-class basis.
# We need to override that to match our schema, where for tags we use the
# tag_type field to identify the kind of object a given tag is. We intend
# to submit a patch to mongoid but since we're not currently using a recent
# version of the library we also need a monkey patch to make our version
# work.
module Mongoid
  module Document
    module ClassMethods
      # The name of the column containing the object's class when Single Table Inheritance is used
      def inheritance_column
        @inheritance_column || '_type'
      end

      # Sets the value of inheritance_column. Example usage:
      #
      #   class Tag
      #     include Mongoid::Document
      #     field :tag_id,   type: String
      #     field :tag_type, type: String
      #     self.inheritance_column = :tag_type
      #   end
      def inheritance_column=(value)
        @inheritance_column = value.to_s
      end
    end
  end

  module Factory
    # Builds a new +Document+ from the supplied attributes.
    #
    # @example Build the document.
    #   Mongoid::Factory.build(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Hash ] options The mass assignment scoping options.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = nil, options = {})
      type = (attributes || {})[klass.inheritance_column]
      if type && klass._types.include?(type)
        type.constantize.new(attributes, options)
      else
        klass.new(attributes, options)
      end
    end

    def from_db(klass, attributes = nil)
      type = (attributes || {})[klass.inheritance_column]
      if type.blank?
        klass.instantiate(attributes)
      else
        type.camelize.constantize.instantiate(attributes)
      end
    end
  end
end