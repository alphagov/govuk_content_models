require "edition"

class BusinessSupportEdition < Edition

  field :short_description, type: String
  field :body, type: String
  field :min_value, type: Integer
  field :max_value, type: Integer
  field :max_employees, type: Integer
  field :organiser, type: String
  field :eligibility, type: String
  field :evaluation, type: String
  field :additional_information, type: String
  field :continuation_link, type: String
  field :will_continue_on, type: String
  field :contact_details, type: String
  field :business_support_identifier, type: String
  index :business_support_identifier

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body, :eligibility, :evaluation, :additional_information]

  validate :min_must_be_less_than_max
  validates :business_support_identifier, :presence => true
  validate :business_support_identifier_unique
  validates_format_of :continuation_link, :with => URI::regexp(%w(http https)), :allow_blank => true

  @fields_to_clone = [:body, :min_value, :max_value, :max_employees, :organiser,
      :eligibility, :evaluation, :additional_information, :continuation_link,
      :will_continue_on, :contact_details, :short_description,
      :business_support_identifier]

  def whole_body
    [short_description, body].join("\n\n")
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
