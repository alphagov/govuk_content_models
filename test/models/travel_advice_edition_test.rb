require "test_helper"

class TravelAdviceEditionTest < ActiveSupport::TestCase
  setup do
    @ta = TravelAdviceEdition.new(:country_slug => "narnia")
  end

  test "country slug must be present" do
    ta = TravelAdviceEdition.new
    ta.valid?
    assert_includes ta.errors.messages[:country_slug], "can't be blank" 
  end

  test "country slug must be unique for state" do
    @ta.save!
    another_edition = FactoryGirl.create(:travel_advice_edition, 
                                         :country_slug => "liliputt", 
                                         :state => "draft")
    another_edition.country_slug = "narnia"
    another_edition.valid?
    assert_includes another_edition.errors.messages[:state], "is already taken"
    another_edition.publish!
    assert another_edition.valid?
  end

  test "a new travel advice edition is a draft" do
    assert @ta.draft?
  end

  test "publishing a draft travel advice edition" do
    @ta.publish
    refute @ta.draft?
    assert @ta.published?
  end
end
