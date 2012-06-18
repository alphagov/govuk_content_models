require "edition"

class BusinessSupportEdition < Edition
  include Parted

  before_save :setup_default_parts, on: :create

  field :short_description, type: String
  field :min_value, type: Integer
  field :max_value, type: Integer

  DEFAULT_PARTS = [
    {title: "Description", slug: "description"},
    {title: "Eligibility", slug: "eligibility"},
    {title: "Evaluation", slug: "evaluation"},
    {title: "Additional information", slug: "additional-information"}
  ]

  def setup_default_parts
    if parts.empty?
      DEFAULT_PARTS.each do |part|
        parts.build(title: part[:title], slug: part[:slug], body: "")
      end
    end
  end
end