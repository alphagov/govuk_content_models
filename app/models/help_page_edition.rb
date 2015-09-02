require "edition"

class HelpPageEdition < Edition
  field :body, type: String

  GOVSPEAK_FIELDS = [:body]

  def whole_body
    self.body
  end
end
