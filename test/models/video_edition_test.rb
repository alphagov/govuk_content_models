require "test_helper"

class VideoEditionTest < ActiveSupport::TestCase
  test "should not be nil when initialized" do
    video = VideoEdition.new
    assert_equal false, video.nil?
  end

  test "should give a friendly (legacy supporting) description of its format" do
    video = VideoEdition.new
    assert_equal "Video", video.format
  end

  test "should allow saving a video URL" do
    video = VideoEdition.new
    assert_equal nil, video.video_url
    video.video_url = "http://www.youtube.com/watch?v=tDkVS-AN4NU"
    assert_equal "http://www.youtube.com/watch?v=tDkVS-AN4NU", video.video_url
  end

  test "should allow saving a video summary" do
    video = VideoEdition.new
    assert_equal nil, video.video_summary
    video.video_summary = "This is a parody of Wonders of the Universe"
    assert_equal "This is a parody of Wonders of the Universe", video.video_summary
  end

  test "should have a whole_body method which is nil if video URL and video summary aren't present" do
    video = VideoEdition.new
    assert_equal nil, video.whole_body
  end

  test "should have a whole_body method which just has the video URL if no summary is present" do
    video = VideoEdition.new
    video.video_url = "http://www.youtube.com/watch?v=tDkVS-AN4NU"
    assert_equal "http://www.youtube.com/watch?v=tDkVS-AN4NU", video.whole_body
  end

  test "should have a whole_body method which just has the video summary if no URL is present" do
    video = VideoEdition.new
    video.video_summary = "This is a summary"
    assert_equal "This is a summary", video.whole_body
  end

  test "should have a whole_body method which has both the video URL and the video summary" do
    video = VideoEdition.new
    video.video_summary = "This is a summary"
    video.video_url = "https://www.gov.uk"
    assert_equal "https://www.gov.uk\n\nThis is a summary", video.whole_body
  end
end
