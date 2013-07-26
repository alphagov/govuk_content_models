require "edition"

class SimpleSmartAnswerEdition < Edition
  class Node
    class Option
      include Mongoid::Document

      embedded_in :node, :class_name => "SimpleSmartAnswerEdition::Node"

      field :label, type: String
      field :slug, type: String
      field :next_node, type: String
      field :order, type: Integer

      default_scope order_by([:order, :asc])

      validates :label, :next_node, presence: true
      validates :slug, :format => {:with => /\A[a-z0-9-]+\z/}

      before_validation :populate_slug_if_blank

      private

      def populate_slug_if_blank
        if self.slug.blank? and self.label.present?
          self.slug = ActiveSupport::Inflector.parameterize(self.label)
        end
      end
    end
  end
end
