require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "should return a hash of the fields" do
    tag = FactoryGirl.build(:live_tag,
      tag_id: "crime",
      tag_type: "section",
      title: "Crime",
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
      FactoryGirl.create(:live_tag, :tag_id => section, :title => section.capitalize)
    end

    %w(pie mash chips).each do |keyword|
      FactoryGirl.create(
        :live_tag,
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
    # This form is deprecated in favour of providing the type as an option
    assert_equal "Crime", Tag.by_tag_id("crime", "section").title
  end

  test "accepts the tag type as an option" do
    assert_equal "Crime", Tag.by_tag_id("crime", type: "section").title
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

  test "should not return missing tags" do
    tag_ids = %w(crime business not_a_real_tag housing)
    tags = Tag.by_tag_ids(tag_ids)

    assert_equal %w(crime business housing), tags.map(&:tag_id)
  end

  test "should not return draft tags unless requested" do
    draft_tag = FactoryGirl.create(:draft_tag,
      tag_id: "draft-tag",
      tag_type: "section",
      title: "A draft tag",
    )

    tag_ids = %w(crime business draft-tag housing)

    assert_equal %w(crime business housing).to_set, Tag.by_tag_ids(tag_ids).map(&:tag_id).to_set
    assert_equal %w(crime business draft-tag housing).to_set, Tag.by_tag_ids(tag_ids, draft: true).map(&:tag_id).to_set

    assert_nil Tag.by_tag_id('draft-tag')
    assert_equal draft_tag, Tag.by_tag_id('draft-tag', draft: true)
  end

  test "should return nil for tags of the wrong type" do
    tag_ids = %w(crime business pie batman)
    tags = Tag.by_tag_ids(tag_ids, "section")
    [2, 3].each do |i| assert_nil tags[i] end
    [0, 1].each do |i| assert_equal tag_ids[i], tags[i].tag_id end
  end

  test "should raise an exception if any tags are missing" do
    assert_raises Tag::MissingTags do
      Tag.validate_tag_ids(%w(crime business batman))
    end
  end

  test "should raise an exception with the wrong tag type" do
    assert_raises Tag::MissingTags do
      Tag.validate_tag_ids(%w(crime business pie chips), "section")
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

  test "should be invalid when tag id already exists for the tag type" do
    Tag.create!(tag_id: "cars", tag_type: "vehicles", title: "Cars")
    Tag.create!(tag_id: "cars", tag_type: "gary-numan-songs", title: "Cars")

    tag = Tag.new(tag_id: "cars", tag_type: "vehicles")

    refute tag.valid?
    assert tag.errors.has_key?(:tag_id)
  end

  test "should validate with TagIdValidator" do
    assert_includes Tag.validators.map(&:class), TagIdValidator
  end

  context "state" do
    setup do
      @atts = { tag_type: 'section', tag_id: 'test', title: 'Test' }
    end

    should "be created in live state" do
      tag = Tag.create(@atts.merge(state: 'live'))

      assert tag.persisted?
      assert_equal 'live', tag.state
    end

    should "be created in draft state" do
      tag = Tag.create(@atts.merge(state: 'draft'))

      assert tag.persisted?
      assert_equal 'draft', tag.state
    end

    should "not be created in another state" do
      tag = Tag.create(@atts.merge(state: 'foo'))

      assert !tag.valid?
      assert tag.errors.has_key?(:state)
    end

    should "be created in live state by default" do
      tag = Tag.create(@atts)

      assert tag.persisted?
      assert_equal 'live', tag.state
    end
  end
end
