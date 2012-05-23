require 'test_helper'

require 'licence_edition'

class LicenceEditionTest < ActiveSupport::TestCase
  should "have correct extra fields" do
    l = FactoryGirl.build(:licence_edition)
    l.licence_identifier = "AB1234"
    l.licence_overview = "Markdown overview of licence..."
    l.safely.save!

    l = LicenceEdition.first
    assert_equal "AB1234", l.licence_identifier
    assert_equal "Markdown overview of licence...", l.licence_overview
  end

  context "validations" do
    setup do
      @l = FactoryGirl.build(:licence_edition)
    end

    should "require a licence identifier" do
      @l.licence_identifier = ''
      assert_equal false, @l.valid?
    end
  end

  should "clone extra fields when cloning edition" do
    licence = FactoryGirl.create(:licence_edition,
                                 :state => "published",
                                 :licence_identifier => "1234",
                                 :licence_overview => "Overview to be cloned")
    new_licence = licence.build_clone

    assert_equal licence.licence_identifier, new_licence.licence_identifier
    assert_equal licence.licence_overview, new_licence.licence_overview
  end
end
