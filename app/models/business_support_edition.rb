require "edition"
require "parted"

class BusinessSupportEdition < Edition
  include Parted

  validate :min_must_be_less_than_max

  field :short_description, type: String
  field :min_value, type: Integer
  field :max_value, type: Integer

  DEFAULT_PARTS = [
    {title: "Description", slug: "description"},
    {title: "Eligibility", slug: "eligibility"},
    {title: "Evaluation", slug: "evaluation"},
    {title: "Additional information", slug: "additional-information"}
  ]

  set_callback(:create, :before) do |document|
    setup_default_parts(DEFAULT_PARTS)
  end

  private

  def min_must_be_less_than_max
    if !min_value.nil? && !max_value.nil? && min_value > max_value
      errors[:min_value] << "Min value must be smaller than max value"
      errors[:max_value] << "Max value must be larger than min value"
    end
  end
end
