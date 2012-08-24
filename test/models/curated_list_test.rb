require "test_helper"

class CuratedListTest < ActiveSupport::TestCase
  test "should validate format of slug" do
    cl = CuratedList.new(slug: 'I am not a valid slug')
    assert !cl.valid?
    assert cl.errors[:slug].any?, "Doesn't have error on slug"
  end
end