require 'test_helper'

class LicenceEditionTest < ActiveSupport::TestCase
  should "have correct extra fields" do
    l = FactoryGirl.build(:licence_edition)
    l.licence_identifier = "AB1234"
    l.licence_short_description = "Short description of licence"
    l.licence_overview = "Markdown overview of licence..."
    l.safely.save!

    l = LicenceEdition.first
    assert_equal "AB1234", l.licence_identifier
    assert_equal "Short description of licence", l.licence_short_description
    assert_equal "Markdown overview of licence...", l.licence_overview
  end

  context "validations" do
    setup do
      @l = FactoryGirl.build(:licence_edition)
    end

    should "require a licence identifier" do
      @l.licence_identifier = ''
      assert_equal false, @l.valid?, "expected licence edition not to be valid"
    end

    should "require a unique licence identifier" do
      FactoryGirl.create(:licence_edition, :licence_identifier => "wibble")
      @l.licence_identifier = "wibble"
      assert ! @l.valid?, "expected licence edition not to be valid"
    end

    should "not require a unique licence identifier for different versions of the same licence edition" do
      @l.state = 'published'
      @l.licence_identifier = 'wibble'
      @l.save!

      new_version = @l.build_clone
      assert_equal 'wibble', new_version.licence_identifier
      assert new_version.valid?, "Expected clone to be valid"
    end
  end

  should "clone extra fields when cloning edition" do
    licence = FactoryGirl.create(:licence_edition,
                                 :state => "published",
                                 :licence_identifier => "1234",
                                 :licence_short_description => "Short description of licence",
                                 :licence_overview => "Overview to be cloned")
    new_licence = licence.build_clone

    assert_equal licence.licence_identifier, new_licence.licence_identifier
    assert_equal licence.licence_short_description, new_licence.licence_short_description
    assert_equal licence.licence_overview, new_licence.licence_overview
  end
end
