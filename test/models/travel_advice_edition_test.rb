require "test_helper"

class TravelAdviceEditionTest < ActiveSupport::TestCase
  setup do
    @ta = FactoryGirl.create(:travel_advice_edition,
                             :country_slug => "narnia",
                             :state => "draft")
  end

  test "country slug must be present" do
    ta = TravelAdviceEdition.new
    ta.valid?
    assert_includes ta.errors.messages[:country_slug], "can't be blank" 
  end

  test "country slug must be unique for state" do
    another_edition = FactoryGirl.create(:travel_advice_edition, 
                                         :country_slug => "liliputt", 
                                         :state => "draft")
    another_edition.country_slug = "narnia"
    another_edition.valid?
    assert_includes another_edition.errors.messages[:state], "is already taken"
  end

  test "country slug may be duplicate across editions with different states" do
    another_edition = FactoryGirl.create(:travel_advice_edition, 
                                         :country_slug => "liliputt", 
                                         :state => "draft")
    another_edition.publish!
    another_edition.country_slug = "narnia"
    assert another_edition.valid?
  end

  test "multiple editions with the same slug may be archived" do
    @ta.archive!
    another_edition = FactoryGirl.create(:travel_advice_edition, 
                                         :country_slug => "narnia", 
                                         :state => "draft")
    assert another_edition.archive!
  end

  test "a new travel advice edition is a draft" do
    assert TravelAdviceEdition.new.draft?
  end

  test "publishing a draft travel advice edition" do
    @ta.publish
    refute @ta.draft?
    assert @ta.published?
  end
end
