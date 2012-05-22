require "parted"
require "whole_edition"

class LicenceEdition < WholeEdition

  field :licence_identifier,  :type => String
  field :short_description,   :type => String

  validates :licence_identifier, :presence => true

  @fields_to_clone = [:licence_identifier, :short_description]
end
