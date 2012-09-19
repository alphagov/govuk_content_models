require "test_helper"

class VideoEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  should "have correct extra fields" do
    v = FactoryGirl.build(:video_edition, panopticon_id: @artefact.id)
    v.video_url = "http://www.youtube.com/watch?v=qySFp3qnVmM"
    v.video_summary = "Coke smoothie"
    v.description = "Description of video"
    v.safely.save!

    v = VideoEdition.first
    assert_equal "http://www.youtube.com/watch?v=qySFp3qnVmM", v.video_url
    assert_equal "Coke smoothie", v.video_summary
    assert_equal "Description of video", v.description
  end

  should "give a friendly (legacy supporting) description of its format" do
    video = VideoEdition.new
    assert_equal "Video", video.format
  end

  context "whole_body" do
    should "combine the video_summary, video_url and description" do
      v = FactoryGirl.build(:video_edition,
                            :panopticon_id => @artefact.id,
                            :video_summary => "Coke smoothie",
                            :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                            :description => "Make a smoothie from a whole can of coke")
      expected = ["Coke smoothie", "http://www.youtube.com/watch?v=qySFp3qnVmM", "Make a smoothie from a whole can of coke"].join("\n\n")
      assert_equal expected, v.whole_body
    end

    should "cope with a field being nil" do
      v = FactoryGirl.build(:video_edition,
                            :panopticon_id => @artefact.id,
                            :video_summary => nil,
                            :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                            :description => "Make a smoothie from a whole can of coke")
      expected = ["", "http://www.youtube.com/watch?v=qySFp3qnVmM", "Make a smoothie from a whole can of coke"].join("\n\n")
      assert_equal expected, v.whole_body
    end
  end

  should "clone extra fields when cloning edition" do
    video = FactoryGirl.create(:video_edition,
                               :panopticon_id => @artefact.id,
                               :state => "published",
                               :video_url => "http://www.youtube.com/watch?v=qySFp3qnVmM",
                               :video_summary => "Coke smoothie",
                               :description => "Description of video")

    new_video = video.build_clone

    assert_equal video.video_url, new_video.video_url
    assert_equal video.video_summary, new_video.video_summary
    assert_equal video.description, new_video.description
  end
end
