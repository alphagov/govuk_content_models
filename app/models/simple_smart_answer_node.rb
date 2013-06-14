class SimpleSmartAnswerNode
  include Mongoid::Document

  embedded_in :edition, :class_name => "SimpleSmartAnswerEdition"

  field :slug, type: String
  field :title, type: String
  field :body, type: String
  field :order, type: Integer
  field :options, type: Hash
  field :kind, type: String

  default_scope order_by([:order, :asc])

  KINDS = [
    'question',
    'outcome'
  ]

  validates :slug, :title, :kind, presence: true
  validates :kind, inclusion: { :in => KINDS }

  validate :outcomes_have_no_options
  validate :all_options_have_labels

  private

  def outcomes_have_no_options
    errors.add(:options, "cannot be added for an outcome") if options.present? and options.any? and kind == "outcome"
  end

  def all_options_have_labels
    errors.add(:options, "must not have blank labels") if options.present? and options.values.select(&:blank?).size > 0
  end
end
