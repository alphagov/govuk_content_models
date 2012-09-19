require "edition"

class VideoEdition < Edition
  field :video_url,     type: String
  field :video_summary, type: String
  field :body,          type: String

  @fields_to_clone = [:video_url, :video_summary, :body]

  def has_video?
    video_url.present?
  end

  def whole_body
    [video_summary, video_url, body].join("\n\n")
  end
end
