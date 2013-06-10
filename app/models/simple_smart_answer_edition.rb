class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :flow, type: Hash
  field :body, type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body, :flow]
end
