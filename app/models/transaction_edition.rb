require "edition"

class TransactionEdition < Edition
  field :introduction, type: String
  field :will_continue_on, type: String
  field :link, type: String
  field :more_information, type: String
  field :need_to_know, type: String
  field :department_analytics_profile, type: String
  field :alternate_methods, type: String

  GOVSPEAK_FIELDS = [:introduction, :more_information, :alternate_methods, :need_to_know]

  validates_format_of :department_analytics_profile, with: /UA-\d+-\d+/i, allow_blank: true

  def indexable_content
    "#{super} #{Govspeak::Document.new(introduction).to_text} #{Govspeak::Document.new(more_information).to_text}".strip
  end

  def whole_body
    [ self.link, self.introduction, self.more_information, self.alternate_methods ].join("\n\n")
  end
end
