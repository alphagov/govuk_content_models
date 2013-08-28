require "test_helper"

class CampaignEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact, :kind => 'campaign', :slug => "start-all-the-campaigns")
  end

  should "have correct extra fields" do
    c = FactoryGirl.build(:campaign_edition, :panopticon_id => @artefact.id)
    c.body = "Start all the campaigns!"
    c.safely.save!

    c = CampaignEdition.first
    assert_equal "Start all the campaigns!", c.body
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
                               :body => "I'm very campaignful")

    new_campaign = campaign.build_clone
    assert_equal campaign.body, new_campaign.body
  end
end
