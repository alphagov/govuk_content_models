require 'test_helper'
require 'taggable'

# This test relies on the fact that artefact uses the taggable module
class TaggableTest < ActiveSupport::TestCase

  TEST_SECTIONS = [['crime', 'Crime'], ['crime/the-police', 'The Police'],
    ['crime/batman', 'Batman']]
  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

  setup do
    TEST_SECTIONS.each do |tag_id, title|
      TagRepository.put(:tag_id => tag_id, :tag_type => 'section', :title => title)
    end
    TEST_KEYWORDS.each do |tag_id, title|
      TagRepository.put(:tag_id => tag_id, :tag_type => 'keyword', :title => title)
    end

    @item = FactoryGirl.create(:artefact)
  end

  test "can set sections" do
    @item.sections = ['crime', 'crime/the-police']
    @item.reconcile_tag_ids

    assert_equal ['crime', 'crime/the-police'], @item.tag_ids, 'Mismatched tags'
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id), 'Mismatched sections'

    assert_equal 'Crime', @item.primary_section.title
  end

  test "can set sections and primary section separately" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime'
    @item.reconcile_tag_ids

    assert_equal ['crime', 'crime/the-police'], @item.tag_ids, 'Mismatched tags'
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id), 'Mismatched sections'

    assert_equal 'Crime', @item.primary_section.title
  end

  test "can set subsection as primary section" do
    @item.sections = ['crime/the-police', 'crime']
    @item.primary_section = 'crime/the-police'
    @item.reconcile_tag_ids
    assert_equal 'The Police', @item.primary_section.title
  end

  test "cannot set non-existent sections" do
    assert_raise RuntimeError do
      @item.sections = ['weevils']
    end
  end

  test "can set primary section to the empty string" do
    pending "does this make sense if there are other sections set?"
    @item.primary_section = 'crime'
    @item.primary_section = ''
    refute @item.primary_section
  end

  test "can set primary section to nil" do
    pending "does this make sense if there are other sections set?"
    @item.primary_section = 'crime'
    @item.primary_section = nil
    refute @item.primary_section
  end

  test "cannot set non-section tags" do
    assert_raise RuntimeError do
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
    @item.reconcile_tag_ids

    assert_equal ['bacon', 'cheese', 'crime'], @item.tag_ids.sort
    assert_equal 'Crime', @item.primary_section.title
  end

  test "appending sections either works or raises an exception" do
    pending "Where do we need this functionality?"

    @item.sections = ['crime']
    begin
      @item.sections << 'crime/the-police'
    rescue RuntimeError
      return  # If the sections list is frozen, that's ok
    end
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id)
  end

  test "setting primary section adds section to tags" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime/batman'
    @item.reconcile_tag_ids
    assert_includes @item.sections.collect(&:tag_id), 'crime/batman'
  end

  test "setting primary section to existing section works" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime/the-police'
    @item.reconcile_tag_ids
    # Note: not testing the order of the sections in this test, just testing
    # that the section is still present and not duplicated
    assert_equal ['crime', 'crime/the-police'], @item.sections.collect(&:tag_id).sort
  end

  test "can prepend tags" do
    pending "This is no longer valid with the new implementation but needs exploration"

    # A bug in earlier versions of the mongoid library meant it would try to be
    # a little too clever dealing with arrays, and in so doing would process
    # modified arrays as $pushAll operators, breaking the array's ordering
    @item.tag_ids = ['crime', 'crime/the-police']
    @item.save
    @item.reload
    assert_equal ['crime', 'crime/the-police'], @item.tag_ids

    @item.tag_ids = ['crime/batman'] + @item.sections
    assert_equal ['crime/batman', 'crime', 'crime/the-police'], @item.tag_ids
    @item.save
    @item.reload
    assert_equal @item.tag_ids, ['crime/batman', 'crime', 'crime/the-police']
  end
end
