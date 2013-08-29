require 'attachable'
require 'edition'

class CampaignEdition < Edition
  include Attachable

  field :body, type: String

  attaches :large_image, :medium_image, :small_image

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body, :large_image_id, :medium_image_id, :small_image_id]

  def whole_body
    self.body
  end
end
