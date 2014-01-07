require "edition"
require "expectant"

class TransactionEdition < Edition

  include Expectant

  field :introduction,      type: String
  field :will_continue_on,  type: String
  field :link,              type: String
  field :more_information,  type: String
  field :alternate_methods, type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:introduction, :more_information, :alternate_methods]

  @fields_to_clone = [:introduction, :will_continue_on, :link,
                      :more_information, :alternate_methods,
                      :minutes_to_complete, :uses_government_gateway,
                      :expectation_ids]

  def indexable_content
    "#{super} #{Govspeak::Document.new(introduction).to_text} #{Govspeak::Document.new(more_information).to_text}".strip
  end

  def whole_body
    [ self.link, self.introduction, self.more_information, self.alternate_methods ].join("\n\n")
  end
end
