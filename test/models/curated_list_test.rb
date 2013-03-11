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

  test "should return artefacts in relationship order, not their natural order" do
    a = FactoryGirl.create(:artefact, name: "A")
    b = FactoryGirl.create(:artefact, name: "B")
    cl = FactoryGirl.create(:curated_list, artefact_ids: [b._id, a._id])
    assert_equal ["B", "A"], cl.artefacts.map(&:name)
  end
end