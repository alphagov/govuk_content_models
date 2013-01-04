require "test_helper"

class TravelAdviceEditionTest < ActiveSupport::TestCase
  setup do
    @ta = TravelAdviceEdition.new
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
