require "test_helper"

class ArtefactTagTest < ActiveSupport::TestCase

  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]
  TEST_LEGACY_SOURCES = [
    ['businesslink', 'Business Link'], ['directgov', 'Directgov'], ['dvla', 'DVLA']
  ]

  setup do
    parent_section = FactoryGirl.create(:tag, :tag_id => 'crime', :tag_type => 'section', :title => 'Crime')
    FactoryGirl.create(:tag, :tag_id => 'crime/the-police', :tag_type => 'section', :title => 'The Police', :parent_id => parent_section.id)
    FactoryGirl.create(:tag, :tag_id => 'crime/batman', :tag_type => 'section', :title => 'Batman', :parent_id => parent_section.id)

    TEST_KEYWORDS.each do |tag_id, title|
      FactoryGirl.create(:tag, :tag_id => tag_id, :tag_type => 'keyword', :title => title)
    end
    TEST_LEGACY_SOURCES.each do |tag_id, title|
      FactoryGirl.create(:tag, :tag_id => tag_id, :tag_type => 'legacy_source', :title => title)
    end
  end

  test "return primary section title when asked for its section" do
    a = FactoryGirl.create(:artefact)
    a.sections = ['crime', 'crime/the-police']
    a.primary_section = 'crime'
    a.reconcile_tag_ids

    assert_equal 'Crime', a.section
  end

  test "returns title of parent and child tags when its primary section has a parent" do
    parent = Tag.by_tag_id('crime', 'section')
    child = Tag.by_tag_id('crime/batman', 'section')
    child.update_attributes parent_id: parent.tag_id

    a = FactoryGirl.create(:artefact)
    a.primary_section = child.tag_id
    a.reconcile_tag_ids

    assert_equal "#{parent.title}:#{child.title}", a.section
  end

  test "stores the tag type and tag id for each tag" do
    a = FactoryGirl.create(:artefact)

    a.sections = ['crime', 'crime/the-police']
    a.legacy_sources = ['businesslink']
    a.keywords = ['bacon']
    a.reconcile_tag_ids

    expected_tags = [
      { tag_id: "crime", tag_type: "section" },
      { tag_id: "crime/the-police", tag_type: "section" },
      { tag_id: "businesslink", tag_type: "legacy_source" },
      { tag_id: "bacon", tag_type: "keyword" },
    ]
    assert_equal ["crime", "crime/the-police", "businesslink", "bacon"], a.tag_ids
    assert_equal expected_tags, a.attributes["tags"]
  end

  test "has legacy_sources tag collection" do
    a = FactoryGirl.build(:artefact)
    a.legacy_sources = ['businesslink', 'dvla']
    a.save

    a = Artefact.first
    assert_equal ["businesslink", "dvla"], a.legacy_source_ids
  end
end
