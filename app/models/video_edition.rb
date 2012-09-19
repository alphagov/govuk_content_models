require "edition"

class VideoEdition < Edition
  field :video_url,     type: String
  field :video_summary, type: String
  field :description,   type: String

  @fields_to_clone = [:video_url, :video_summary, :description]

  def has_video?
    video_url.present?
  end

  def whole_body
    [video_summary, video_url, description].join("\n\n")
  end
end
