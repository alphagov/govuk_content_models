require "edition"
require "parted"

class BusinessSupportEdition < Edition
  include Parted

  field :short_description, type: String
  field :min_value, type: Integer
  field :max_value, type: Integer
  field :max_employees, type: Integer
  field :organiser, type: String
  field :continuation_link, type: String
  field :will_continue_on, type: String
  field :contact_details, type: String
  field :business_support_identifier, type: String

  validate :min_must_be_less_than_max
  validate :business_support_identifier_unique
  validates_format_of :continuation_link, :with => URI::regexp(%w(http https)), :allow_blank => true

  before_save :setup_default_parts, on: :create

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

  private

  def min_must_be_less_than_max
    if !min_value.nil? && !max_value.nil? && min_value > max_value
      errors[:min_value] << "Min value must be smaller than max value"
      errors[:max_value] << "Max value must be larger than min value"
    end
  end
  
  def business_support_identifier_unique
    if self.class.where(:business_support_identifier => business_support_identifier,
                        :panopticon_id.ne => panopticon_id).any?
      errors.add(:business_support_identifier, :taken)
    end
  end
end
