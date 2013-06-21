class SimpleSmartAnswerEdition < Edition
  class Node
    class Option
      include Mongoid::Document

      embedded_in :node, :class_name => "SimpleSmartAnswerEdition::Node"

      field :label, type: String
      field :next, type: String
      field :order, type: Integer

      default_scope order_by([:order, :asc])

      validates :label, :next, presence: true
    end
  end
end
