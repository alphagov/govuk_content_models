require "test_helper"

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
      description: nil,
      short_description: nil
    }
    assert_equal expected_hash, tag.as_json
  end

  test "sections should be instantiated as Section" do
    tag = Tag.create!(
      tag_id: "crime",
      tag_type: "section",
      title: "Crime"
    )
    reloaded = Tag.where(tag_id: "crime").first
    assert reloaded.is_a?(Section), "#{reloaded.class} not instantiated as a Section"
  end
end
