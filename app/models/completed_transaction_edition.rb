require "edition"

class CompletedTransactionEdition < Edition

  field :body, type: String
  embeds_one :organ_donor_promotion, class_name: "PresentationToggle"

  GOVSPEAK_FIELDS = [:body]

  @fields_to_clone = [:body]

  def whole_body
    self.body
  end
end
