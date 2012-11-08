require "expectant"
require "local_service"
require "edition"

class LocalTransactionEdition < Edition
  include Expectant

  field :lgsl_code,         type: Integer
  field :lgil_override,     type: Integer
  field :introduction,      type: String
  field :more_information,  type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:introduction, :more_information]

  @fields_to_clone = [
    :lgsl_code, :introduction, :more_information,
    :minutes_to_complete, :expectation_ids
  ]

  validate :valid_lgsl_code

  def valid_lgsl_code
    if ! self.service
      errors.add(:lgsl_code, "#{lgsl_code} not recognised")
    end
  end

  def format_name
    "Local transaction"
  end

  def search_format
    "transaction"
  end

  def service
    LocalService.find_by_lgsl_code(lgsl_code)
  end

  def service_provided_by?(snac)
    authority = LocalAuthority.find_by_snac(snac)
    authority && authority.provides_service?(lgsl_code)
  end

  def whole_body
    self.introduction
  end

end
