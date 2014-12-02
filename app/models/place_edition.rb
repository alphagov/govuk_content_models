require "edition"

class PlaceEdition < Edition
  field :introduction, type: String
  field :more_information, type: String
  field :need_to_know, type: String
  field :place_type, type: String
  field :minutes_to_complete, type: String
  field :uses_government_gateway, type: Boolean

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:introduction, :more_information, :need_to_know]

  @fields_to_clone = [:introduction, :more_information, :place_type, :need_to_know]

  def whole_body
    self.introduction
  end

end
