require "parted"
require "edition"

class LicenceEdition < Edition

  field :licence_identifier,  :type => String
  field :licence_short_description, :type => String
  field :licence_overview,  :type => String

  validates :licence_identifier, :presence => true

  @fields_to_clone = [:licence_identifier, :licence_overview]
end
