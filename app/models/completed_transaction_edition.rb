require "edition"

class CompletedTransactionEdition < Edition
  include PresentationToggles

  field :body, type: String

  GOVSPEAK_FIELDS = [:body]

  @fields_to_clone = [:body, :presentation_toggles]

  def whole_body
    self.body
  end
end
