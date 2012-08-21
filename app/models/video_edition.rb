require "edition"

class VideoEdition < Edition
  field :video_url,     type: String
  field :video_summary, type: String

  validates_with SafeHtml

  @fields_to_clone = [:video_url, :video_summary]

  def has_video?
    video_url.present?
  end

  def whole_body
    if video_summary and video_url
      "#{video_url}\n\n#{video_summary}"
    else
      video_url || video_summary
    end
  end
end
