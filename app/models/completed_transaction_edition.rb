require "edition"

class CompletedTransactionEdition < Edition
  include PresentationToggles

  field :body, type: String

  GOVSPEAK_FIELDS = [:body]

  def whole_body
    self.body
  end
end
