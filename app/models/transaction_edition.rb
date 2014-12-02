require "edition"

class TransactionEdition < Edition
  field :introduction, type: String
  field :will_continue_on, type: String
  field :link, type: String
  field :more_information, type: String
  field :need_to_know, type: String
  field :alternate_methods, type: String
  field :minutes_to_complete, type: String
  field :uses_government_gateway, type: Boolean

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:introduction, :more_information, :alternate_methods, :need_to_know]

  @fields_to_clone = [:introduction, :will_continue_on, :link,
                      :more_information, :alternate_methods,
                      :minutes_to_complete, :uses_government_gateway,
                      :need_to_know]

  def indexable_content
    "#{super} #{Govspeak::Document.new(introduction).to_text} #{Govspeak::Document.new(more_information).to_text}".strip
  end

  def whole_body
    [ self.link, self.introduction, self.more_information, self.alternate_methods ].join("\n\n")
  end
end
