require "edition"
require "safe_html"

class AnswerEdition < Edition
  field :body, type: String

  @fields_to_clone = [:body]

  def indexable_content
    content = super
    return content unless latest_edition?
    "#{content} #{body}".strip
  end

  def whole_body
    self.body
  end

end
