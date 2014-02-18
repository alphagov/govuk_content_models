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

  setup do
    %w(crime business housing).each do |section|
      FactoryGirl.create(:tag, :tag_id => section, :title => section.capitalize)
    end

    %w(pie mash chips).each do |keyword|
      FactoryGirl.create(
        :tag,
        :tag_id => keyword,
        :title => keyword.capitalize,
        :tag_type => "keyword"
      )
    end
  end

  test "should load by tag ID" do
    assert_equal "Crime", Tag.by_tag_id("crime").title
  end

  test "should load by tag ID and type" do
    assert_equal "Crime", Tag.by_tag_id("crime", "section").title
  end

  test "should not load an incorrectly-typed tag" do
    assert_nil Tag.by_tag_id("crime", "keyword")
  end

  test "should return nil if tag does not exist" do
    assert_nil Tag.by_tag_id("batman")
  end

  test "should return multiple tags" do
    assert_equal(
      %w(Crime Business),
      Tag.by_tag_ids(%w(crime business)).map(&:title)
    )
  end

  test "should return nil for missing tags" do
    tag_ids = %w(crime business batman housing)
    tags = Tag.by_tag_ids(tag_ids)
    assert_nil tags[2]
    [0, 1, 3].each do |i|
      assert_equal tag_ids[i], tags[i].tag_id
    end
  end

  test "should return nil for tags of the wrong type" do
    tag_ids = %w(crime business pie batman)
    tags = Tag.by_tag_ids(tag_ids, "section")
    [2, 3].each do |i| assert_nil tags[i] end
    [0, 1].each do |i| assert_equal tag_ids[i], tags[i].tag_id end
  end

  test "should return multiple tags from the bang method" do
    assert_equal(
      %w(Crime Business),
      Tag.by_tag_ids!(%w(crime business)).map(&:title)
    )
  end

  test "should raise an exception if any tags are missing" do
    assert_raises Tag::MissingTags do
      Tag.by_tag_ids!(%w(crime business batman))
    end
  end

  test "should raise an exception with the wrong tag type" do
    assert_raises Tag::MissingTags do
      Tag.by_tag_ids!(%w(crime business pie chips), "section")
    end
  end

  test "should return tags given a list of tag ids and tag types" do
    tag_types_and_ids = [
      { tag_type: "section", tag_id: "crime" },
      { tag_type: "section", tag_id: "business" },
      { tag_type: "keyword", tag_id: "pie" },
      { tag_type: "keyword", tag_id: "chips" }
    ]
    tags = Tag.by_tag_types_and_ids(tag_types_and_ids)

    assert_equal %w{Business Chips Crime Pie}, tags.map(&:title).sort
  end
end
