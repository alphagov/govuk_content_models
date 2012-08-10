require "test_helper"
require "tag"

class TagTest < ActiveSupport::TestCase
  test "should return a hash of the fields" do
    tag = Tag.new(
      tag_id: "crime",
      tag_type: "section",
      title: "Crime"
    )
    expected_hash = {
      id: "crime",
      title: "Crime",
      type: "section",
      description: nil
    }
    assert_equal expected_hash, tag.as_json
  end
end
