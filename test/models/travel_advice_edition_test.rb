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

  test "country slug must be unique" do
    @ta.save!
    another_edition = TravelAdviceEdition.new(:country_slug => "narnia")
    another_edition.valid?
    assert_includes another_edition.errors.messages[:country_slug], "is already taken"
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
