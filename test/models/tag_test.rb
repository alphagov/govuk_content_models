require "test_helper"
require "tag"

class TagTest < ActiveSupport::TestCase
  test "should return a hash of the fields" do
    tag = Tag.new(:tag_id => "crime", :tag_type => "section", :title => "Crime")
    assert_equal tag.as_json, {:id=>"crime", :title=>"Crime", :type=>"section"}
  end

  test "section tags should be able to have parents" do
    parent = SectionTag.create(tag_id: "crime", tag_type: "section", title: "Crime")
    child = SectionTag.create(parent_id: "crime", tag_id: "punishment", tag_type: "section", title: "Punishment")
    assert parent.persisted?, "Failed to save parent tag"
    assert child.persisted?, "Failed to save child tag"

    assert_equal parent, child.parent, "Child not returning correct parent"
  end
end
