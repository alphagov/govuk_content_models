require "test_helper"
require "tag"

class TagTest < ActiveSupport::TestCase
  test "should return a hash of the fields" do
    tag = Tag.new(
      tag_id: "crime",
      tag_type: "section",
      title: "Crime"
    )
    assert_equal tag.as_json, {id: "crime", title: "Crime", type: "section", description: nil}
  end
end
