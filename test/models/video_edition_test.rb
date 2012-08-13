require "test_helper"

class VideoEditionTest < ActiveSupport::TestCase
  test "should not be nil when initialized" do
    video = VideoEdition.new
    refute video.nil?
  end

  test "should give a friendly (legacy supporting) description of its format" do
    video = VideoEdition.new
    assert_equal "Video", video.format
  end

  test "should have a whole_body method which is nil if video URL and video summary aren't present" do
    video = VideoEdition.new
    assert_nil video.whole_body
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
