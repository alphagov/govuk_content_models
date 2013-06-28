require "edition"
require_relative 'simple_smart_answer_edition/node'
require_relative 'simple_smart_answer_edition/node/option'

class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :body, type: String

  # We would use an embedded association to nodes here, however there is a
  # known issue with all versions of Mongoid where a conflict can arise on
  # save for documents with more than one level of embedded hierarchy and
  # which use nested attributes. For now, we're going to use a relational
  # association here.

  # This issue is already noted in the Mongoid GitHub repository.
  # https://github.com/mongoid/mongoid/issues/2989

  has_many :nodes, :class_name => "SimpleSmartAnswerEdition::Node",
                   :foreign_key => "edition_id",
                   :autosave => true,
                   :dependent => :destroy

  accepts_nested_attributes_for :nodes, allow_destroy: true

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body]

  def whole_body
    body
  end

  def build_clone(edition_class=nil)
    new_edition = super(edition_class)
    new_edition.body = self.body

    if new_edition.is_a?(SimpleSmartAnswerEdition)
      self.nodes.each {|n| new_edition.nodes << n.clone }
    end

    new_edition
  end

  def initial_node
    self.nodes.first
  end
end
