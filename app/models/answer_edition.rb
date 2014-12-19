require "edition"

class AnswerEdition < Edition
  field :body, type: String

  GOVSPEAK_FIELDS = [:body]

  @fields_to_clone = [:body]

  def whole_body
    self.body
  end
end
