require 'test_helper'

class TagRepositoryTest < ActiveSupport::TestCase

  setup do
    TagRepository.put(tag_id: "crime", tag_type: "section",
                      title: "Crime")
    TagRepository.put(tag_id: "crime/the-police", tag_type: "section",
                      title: "The Police")
    TagRepository.put(tag_id: "cheese", tag_type: "keyword",
                      title: "Cheese")
  end

  test "should return all tags" do
    all_tag_ids = TagRepository.load_all.map(&:tag_id).sort
    assert_equal ["cheese", "crime", "crime/the-police"], all_tag_ids
  end

  test "should filter tags by type" do
    section_tags = TagRepository.load_all(tag_type: "section")
    assert_equal ["crime", "crime/the-police"], section_tags.map(&:tag_id).sort
  end

  test "should return empty list when no tags" do
    assert_equal 0, TagRepository.load_all(tag_type: "weevil").count
  end

end
