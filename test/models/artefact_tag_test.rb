require "test_helper"

class ArtefactTagTest < ActiveSupport::TestCase

  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

  setup do
    parent_section = FactoryGirl.create(:live_tag, :tag_id => 'crime', :tag_type => 'section', :title => 'Crime')
    FactoryGirl.create(:live_tag, :tag_id => 'crime/the-police', :tag_type => 'section', :title => 'The Police', :parent_id => parent_section.id)
    FactoryGirl.create(:live_tag, :tag_id => 'crime/batman', :tag_type => 'section', :title => 'Batman', :parent_id => parent_section.id)

    TEST_KEYWORDS.each do |tag_id, title|
      FactoryGirl.create(:live_tag, :tag_id => tag_id, :tag_type => 'keyword', :title => title)
    end
  end

  test "return primary section title when asked for its section" do
    a = FactoryGirl.create(:artefact)
    a.sections = ['crime', 'crime/the-police']
    a.primary_section = 'crime'

    assert_equal 'Crime', a.section
  end

  test "returns title of parent and child tags when its primary section has a parent" do
    parent = Tag.by_tag_id('crime', 'section')
    child = Tag.by_tag_id('crime/batman', 'section')
    child.update_attributes parent_id: parent.tag_id

    a = FactoryGirl.create(:artefact)
    a.primary_section = child.tag_id

    assert_equal "#{parent.title}:#{child.title}", a.section
  end

  test "stores the tag type and tag id for each tag" do
    a = FactoryGirl.create(:artefact)

    a.sections = ['crime', 'crime/the-police']
    a.keywords = ['bacon']

    expected_tags = [
      { "tag_id" => "crime", "tag_type" => "section" },
      { "tag_id" => "crime/the-police", "tag_type" => "section" },
      { "tag_id" => "bacon", "tag_type" => "keyword" },
    ]
    assert_equal ["crime", "crime/the-police", "bacon"], a.tag_ids
    assert_equal expected_tags, a.attributes["tags"]
  end
end
