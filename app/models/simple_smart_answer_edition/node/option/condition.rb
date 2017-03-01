class SimpleSmartAnswerEdition < Edition
  class Node
    class Option
      class Condition
        include Mongoid::Document

        embedded_in :option, class_name: "SimpleSmartAnswerEdition::Node::Option"

        field :slug, type: String
        field :label, type: String
        field :next_node, type: String
        field :order, type: Integer

        default_scope lambda { order_by(order: :asc) }

        validates :slug, :label, :next_node, presence: true
        validates :slug, format: { with: /\A[a-z0-9-]+\z/ }
      end
    end
  end
end
