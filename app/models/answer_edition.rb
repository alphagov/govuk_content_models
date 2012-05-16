require "whole_edition"

class AnswerEdition < WholeEdition
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
