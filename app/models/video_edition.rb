require "edition"

class VideoEdition < Edition
  field :video_url,     type: String
  field :video_summary, type: String

  @fields_to_clone = [:video_url, :video_summary]

  def has_video?
    video_url.present?
  end

  def whole_body
    return nil if video_summary.nil? and video_url.nil?
    return "#{video_url}" if video_summary.nil?
    return "#{video_summary}" if video_url.nil?
    "#{video_url}\n\n#{video_summary}"
  end
end
