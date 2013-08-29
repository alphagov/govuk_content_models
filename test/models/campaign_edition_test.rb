require "test_helper"

class CampaignEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact, :kind => 'campaign', :slug => "start-all-the-campaigns")
  end

  should "have correct extra fields" do
    c = FactoryGirl.build(:campaign_edition, :panopticon_id => @artefact.id)
    c.body = "Start all the campaigns!"
    c.large_image_id = "large-image-id-from-the-asset-manager"
    c.medium_image_id = "medium-image-id-from-the-asset-manager"
    c.small_image_id = "small-image-id-from-the-asset-manager"
    c.safely.save!

    c = CampaignEdition.first
    assert_equal "Start all the campaigns!", c.body
    assert_equal "large-image-id-from-the-asset-manager", c.large_image_id
    assert_equal "medium-image-id-from-the-asset-manager", c.medium_image_id
    assert_equal "small-image-id-from-the-asset-manager", c.small_image_id
  end

  should "give a friendly (legacy supporting) description of its format" do
    campaign = CampaignEdition.new
    assert_equal "Campaign", campaign.format
  end

  should "return the body as whole_body" do
    campaign = FactoryGirl.build(:campaign_edition,
                          :panopticon_id => @artefact.id,
                          :body => "Something")
    assert_equal campaign.body, campaign.whole_body
  end

  should "clone extra fields when cloning edition" do
    campaign = FactoryGirl.create(:campaign_edition,
                               :panopticon_id => @artefact.id,
                               :state => "published",
                               :body => "I'm very campaignful",
                               :large_image_id => "large-image",
                               :medium_image_id => "medium-image",
                               :small_image_id => "small-image" )

    new_campaign = campaign.build_clone
    assert_equal campaign.body, new_campaign.body
    assert_equal campaign.large_image_id, new_campaign.large_image_id
    assert_equal campaign.medium_image_id, new_campaign.medium_image_id
    assert_equal campaign.small_image_id, new_campaign.small_image_id
  end
end
