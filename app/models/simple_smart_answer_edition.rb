class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :nodes, type: Hash
  field :body, type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body, :nodes]

  def whole_body
    body
  end
end
