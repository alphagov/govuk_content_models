require "test_helper"

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
                  contact_address: ["Line one", "line two", "line three"],
                  contact_url: "http://example.gov/contact",
                  contact_phone: "0000000000",
                  contact_email: "contact@example.gov")
    authority = LocalAuthority.first
    assert_equal "Example", authority.name
    assert_equal "AA00", authority.snac
    assert_equal 1, authority.local_directgov_id
    assert_equal "county", authority.tier
    assert_equal ["Line one", "line two", "line three"], authority.contact_address
    assert_equal "http://example.gov/contact", authority.contact_url
    assert_equal "0000000000", authority.contact_phone
    assert_equal "contact@example.gov", authority.contact_email
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
