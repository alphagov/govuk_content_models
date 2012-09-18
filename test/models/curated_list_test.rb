require "test_helper"

class CuratedListTest < ActiveSupport::TestCase
  test "should validate format of slug" do
    cl = CuratedList.new(slug: 'I am not a valid slug')
    assert !cl.valid?
    assert cl.errors[:slug].any?, "Doesn't have error on slug"
  end

  test "should include ability to have a section tag" do
    cl = FactoryGirl.create(:curated_list)
    tag = FactoryGirl.create(:tag, tag_id: 'batman', title: 'Batman', tag_type: 'section')

    cl.sections = ['batman']
    cl.save

    assert_equal [tag], cl.sections
  end
end