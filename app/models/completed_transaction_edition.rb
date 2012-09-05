require "edition"
require "safe_html"

class CompletedTransactionEdition < Edition
  field :body, type: String

  @fields_to_clone = [:body]

  def whole_body
    self.body
  end

end
