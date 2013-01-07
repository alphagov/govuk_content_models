require "edition"
require "safe_html"

class AnswerEdition < Edition
  field :body, type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]

  @fields_to_clone = [:body]

  def indexable_content
    "#{super} #{body}".strip
  end

  def whole_body
    self.body
  end
end
