require 'test_helper'

# This test relies on the fact that artefact uses the taggable module
class TaggableTest < ActiveSupport::TestCase

  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

  setup do
    @parent_section = FactoryGirl.create(:tag, :tag_id => 'crime', :tag_type => 'section', :title => 'Crime')
    FactoryGirl.create(:tag, :tag_id => 'crime/the-police', :tag_type => 'section', :title => 'The Police', :parent_id => @parent_section.id)
    FactoryGirl.create(:tag, :tag_id => 'crime/batman', :tag_type => 'section', :title => 'Batman', :parent_id => @parent_section.id)
    @draft_section = FactoryGirl.create(:tag, parent_id: @parent_section.id, state: 'draft')

    TEST_KEYWORDS.each do |tag_id, title|
      FactoryGirl.create(:tag, :tag_id => tag_id, :tag_type => 'keyword', :title => title)
    end

    @item = FactoryGirl.create(:artefact)
  end

  test "can set sections" do
    @item.sections = ['crime', 'crime/the-police']

    assert_equal ['crime', 'crime/the-police'], @item.tag_ids, 'Mismatched tags'
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id), 'Mismatched sections'

    assert_equal 'Crime', @item.primary_section.title
  end

  test "can set sections and primary section separately" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime'

    assert_equal ['crime', 'crime/the-police'], @item.tag_ids, 'Mismatched tags'
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id), 'Mismatched sections'

    assert_equal 'Crime', @item.primary_section.title
  end

  test "can set subsection as primary section" do
    @item.sections = ['crime/the-police', 'crime']
    @item.primary_section = 'crime/the-police'
    assert_equal 'The Police', @item.primary_section.title
  end

  test "cannot set non-existent sections" do
    assert_raise Tag::MissingTags do
      @item.sections = ['weevils']
    end
  end

  test "cannot set non-section tags" do
    assert_raise Tag::MissingTags do
      @item.sections = ['crime', 'bacon']
    end
  end

  test "can set no sections" do
    @item.sections = ['crime', 'crime/the-police']
    @item.sections = []
    assert_equal [], @item.sections

    refute @item.primary_section
  end

  test "setting sections doesn't break other tags" do
    @item.keywords = ['cheese', 'bacon']
    @item.sections = ['crime']
    @item.primary_section = 'crime'

    assert_equal ['bacon', 'cheese', 'crime'], @item.tag_ids.sort
    assert_equal 'Crime', @item.primary_section.title
  end

  test "setting primary section adds section to tags" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime/batman'

    assert_includes @item.sections.collect(&:tag_id), 'crime/batman'
  end

  test "setting primary section to existing section works" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime/the-police'
    # Note: not testing the order of the sections in this test, just testing
    # that the section is still present and not duplicated
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id).sort
  end

  test "setting primary section to existing section reorders correctly" do
    @item.sections = ['crime', 'crime/the-police']
    @item.save!

    @item.primary_section = 'crime/batman'
    @item.save!

    assert_equal 'crime/batman', @item.primary_section.tag_id
    assert_equal ['crime/batman', 'crime', 'crime/the-police'], @item.sections.collect(&:tag_id)
  end

  test "can set tags using foo_ids= type method" do
    @item.keyword_ids = ['bacon']
    @item.save!

    @item.reload

    assert_equal ['bacon'], @item.keyword_ids
  end

  test "can set tags of type to be nil" do
    @item.section_ids = nil
    @item.save!

    assert_equal [], @item.section_ids

    @item.sections = nil
    @item.save!

    assert_equal [], @item.section_ids
  end

  test "returns draft tags only if requested" do
    @item.section_ids = [@parent_section.tag_id, @draft_section.tag_id]
    @item.save!

    assert_equal [@parent_section.tag_id], @item.section_ids
    assert_equal [@parent_section.tag_id, @draft_section.tag_id], @item.section_ids(draft: true)

    assert_equal [@parent_section], @item.sections
    assert_equal [@parent_section, @draft_section], @item.sections(draft: true)
  end
end
