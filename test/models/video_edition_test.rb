require "test_helper"

class VideoEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  should "have correct extra fields" do
    v = FactoryGirl.build(:video_edition, panopticon_id: @artefact.id)
    v.video_url = "http://www.youtube.com/watch?v=qySFp3qnVmM"
    v.video_summary = "Coke smoothie"
    v.safely.save!

    v = VideoEdition.first
    assert_equal "http://www.youtube.com/watch?v=qySFp3qnVmM", v.video_url
    assert_equal "Coke smoothie", v.video_summary
  end

  should "give a friendly (legacy supporting) description of its format" do
    video = VideoEdition.new
    assert_equal "Video", video.format
  end

  context "whole_body" do
    should "have a whole_body method which is nil if video URL and video summary aren't present" do
      video = VideoEdition.new
      assert_nil video.whole_body
    end

    should "have a whole_body method which just has the video URL if no summary is present" do
      video = VideoEdition.new
      video.video_url = "http://www.youtube.com/watch?v=tDkVS-AN4NU"
      assert_equal "http://www.youtube.com/watch?v=tDkVS-AN4NU", video.whole_body
    end

    should "have a whole_body method which just has the video summary if no URL is present" do
      video = VideoEdition.new
      video.video_summary = "This is a summary"
      assert_equal "This is a summary", video.whole_body
    end

    should "have a whole_body method which has both the video URL and the video summary" do
      video = VideoEdition.new
      video.video_summary = "This is a summary"
      video.video_url = "https://www.gov.uk"
      assert_equal "https://www.gov.uk\n\nThis is a summary", video.whole_body
    end
  end

  should "clone extra fields when cloning edition" do
    video = FactoryGirl.create(:video_edition,
                               :panopticon_id => @artefact.id,
                               :state => "published",
                               :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                               :video_summary => "Coke smoothie")

    new_video = video.build_clone

    assert_equal video.video_url, new_video.video_url
    assert_equal video.video_summary, new_video.video_summary
  end
end
