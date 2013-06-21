require_relative 'simple_smart_answer_edition/node'
require_relative 'simple_smart_answer_edition/node/option'

class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :body, type: String

  embeds_many :nodes, :class_name => "SimpleSmartAnswerEdition::Node"

  accepts_nested_attributes_for :nodes, allow_destroy: true

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body]

  def whole_body
    body
  end

  def build_clone(edition_class=nil)
    new_edition = super(edition_class)
    new_edition.body = whole_body

    if new_edition.is_a?(SimpleSmartAnswerEdition)
      new_edition.nodes = self.nodes.map {|n| n.dup }
    end

    new_edition
  end

  def initial_node
    self.nodes.first
  end
end
