require_relative "../test_helper"

describe LocalAuthority do
  before :each do
    LocalAuthority.delete_all
  end

  it "should create an authority with correct field types" do
    # Although it may seem overboard, this test is helpful to confirm
    # the correct field types are being used on the model
    LocalAuthority.create!(
                  name: "Example",
                  snac: "AA00",
                  local_directgov_id: 1,
                  tier: "county",
                  homepage_url: 'http://example.gov/')
    authority = LocalAuthority.first
    assert_equal "Example", authority.name
    assert_equal "AA00", authority.snac
    assert_equal 1, authority.local_directgov_id
    assert_equal "county", authority.tier
    assert_equal "http://example.gov/", authority.homepage_url
  end

  describe "validating local_interactions" do
    before :each do
      @authority = FactoryGirl.create(:local_authority)
    end

    it "should require a lgsl_code and lgil_code" do
      li = @authority.local_interactions.build
      refute li.valid?
      assert_equal ["can't be blank"], li.errors[:lgsl_code]
      assert_equal ["can't be blank"], li.errors[:lgil_code]
    end

    it "should not allow duplicate lgsl/lgil pairs" do
      li1 = @authority.local_interactions.create!(:lgsl_code => 42, :lgil_code => 8, :url => "http://www.example.com/one")
      li2 = @authority.local_interactions.build(:lgsl_code => 42, :lgil_code => 8, :url => "http://www.example.com/two")

      refute li2.valid?
      assert_equal ["is already taken"], li2.errors[:lgil_code]

      li2.lgil_code = 3
      assert li2.valid?
    end

    it "should only validate uniqueness within the authority" do
      authority2 = FactoryGirl.create(:local_authority)
      li1 = @authority.local_interactions.create!(:lgsl_code => 42, :lgil_code => 8, :url => "http://www.example.com/one")
      li2 = authority2.local_interactions.build(:lgsl_code => 42, :lgil_code => 8, :url => "http://www.example.com/two")

      assert li2.valid?
    end
  end

  describe "preferred_interaction_for" do
    before :each do
      @authority = FactoryGirl.create(:local_authority)
      @lgsl_code = "142"
    end

    describe "with no LIGL specified" do
      it "should return the lowest LGIL that's not 8" do
        @interaction1 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => 12)
        @interaction2 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION)
        @interaction3 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => 9)

        assert_equal @interaction3, @authority.preferred_interaction_for(@lgsl_code)
      end

      it "should return LGIL 8 if there are no others" do
        @interaction2 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION)

        assert_equal @interaction2, @authority.preferred_interaction_for(@lgsl_code)
      end
    end

    describe "with an LGIL specified" do
      it "should return the interaction for the specified LGIL" do
        @interaction1 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => 12)
        @interaction2 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION)
        @interaction3 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => 9)

        assert_equal @interaction2, @authority.preferred_interaction_for(@lgsl_code, 8)
      end

      it "should return nil if there is no interaction with the specified LGIL" do
        @interaction1 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => 12)
        @interaction2 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => LocalInteraction::LGIL_CODE_PROVIDING_INFORMATION)
        @interaction3 = FactoryGirl.create(:local_interaction, :local_authority => @authority, :lgsl_code => @lgsl_code,
                                           :lgil_code => 9)

        assert_equal nil, @authority.preferred_interaction_for(@lgsl_code, 3)
      end
    end
  end
end
