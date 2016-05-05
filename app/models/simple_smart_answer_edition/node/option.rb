require "edition"

class SimpleSmartAnswerEdition < Edition
  class Node
    class Option
      include Mongoid::Document

      embedded_in :node, :class_name => "SimpleSmartAnswerEdition::Node"
      embeds_many :conditions, class_name: "SimpleSmartAnswerEdition::Node::Option::Condition"

      accepts_nested_attributes_for :conditions, allow_destroy: true

      field :label, type: String
      field :slug, type: String
      field :next_node, type: String
      field :order, type: Integer

      default_scope lambda { order_by(order: :asc) }

      validates :label, presence: true
      validates :slug, :format => {:with => /\A[a-z0-9-]+\z/}
      validate :either_next_node_or_conditions

      before_validation :populate_slug

      private

      def populate_slug
        if label.present? && !slug_changed?
          self.slug = ActiveSupport::Inflector.parameterize(label)
        end
      end

      def either_next_node_or_conditions
        if next_node
          errors.add(:conditions, "cannot be added when the next node is defined") if conditions.present? && conditions.any?
        else
          errors.add(:next_node, "must be populated when there are no conditions defined") unless conditions.present? && conditions.any?
        end
      end
    end
  end
end
