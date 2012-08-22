require "edition"

class LicenceEdition < Edition

  field :licence_identifier,  :type => String
  field :licence_short_description, :type => String
  field :licence_overview,  :type => String

  validates :licence_identifier, :presence => true
  validate :licence_identifier_unique

  @fields_to_clone = [:licence_identifier, :licence_short_description, :licence_overview]

  def whole_body
    [licence_short_description, licence_overview].join("\n\n")
  end

  private
  def licence_identifier_unique
    if self.class.where(:licence_identifier => licence_identifier, :panopticon_id.ne => panopticon_id).any?
      errors.add(:licence_identifier, :taken)
    end
  end
end
