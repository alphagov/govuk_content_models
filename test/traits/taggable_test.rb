require 'test_helper'
require 'taggable'

class TaggableTest < ActiveSupport::TestCase

  TEST_SECTIONS = [['crime', 'Crime'], ['crime/the-police', 'The Police'],
    ['crime/batman', 'Batman']]
  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

  class TaggableItem
    include Mongoid::Document

    def save
    end

    include Taggable
    stores_tags_for :sections, :writing_teams, :propositions, :audiences
    has_primary_tag_for :section

  end

  setup do
    TEST_SECTIONS.each do |tag_id, title|
      TagRepository.put(:tag_id => tag_id, :tag_type => 'section', :title => title)
    end
    TEST_KEYWORDS.each do |tag_id, title|
      TagRepository.put(:tag_id => tag_id, :tag_type => 'keyword', :title => title)
    end

    @item = TaggableItem.new
  end

  test "can set sections" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime'
    @item.reconcile_tags

    assert_equal ['crime', 'crime/the-police'], @item.tag_ids, 'Mismatched tags'
    assert_equal ['crime', 'crime/the-police'], @item.sections, 'Mismatched sections'

    assert_equal 'Crime', @item.primary_section
  end

  test "can set subsection as primary section" do
    @item.sections = ['crime/the-police', 'crime']
    @item.primary_section = 'crime/the-police'
    @item.reconcile_tags
    assert_equal 'Crime:The Police', @item.primary_section
  end

  test "cannot set non-existent sections" do
    assert_raise RuntimeError do
      @item.sections = ['weevils']
    end
  end

  test "can set primary section to the empty string" do
    @item.primary_section = 'crime'
    @item.primary_section = ''
    refute @item.primary_section
  end

  test "can set primary section to nil" do
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
    @item.audiences = ['cheese', 'bacon']
    @item.sections = ['crime']
    @item.primary_section = 'crime'
    @item.reconcile_tags

    assert_equal ['bacon', 'cheese', 'crime'], @item.tag_ids.sort
    assert_equal 'Crime', @item.primary_section.name
  end

  test "appending sections either works or raises an exception" do
    @item.sections = ['crime']
    begin
      @item.sections << 'crime/the-police'
    rescue RuntimeError
      return  # If the sections list is frozen, that's ok
    end
    assert_equal ['crime', 'crime/the-police'], @item.sections
  end

  test "setting primary section adds section to tags" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime/batman'
    @item.reconcile_tags
    assert_includes @item.sections, 'crime/batman'
  end

  test "setting primary section to existing section works" do
    @item.sections = ['crime', 'crime/the-police']
    @item.primary_section = 'crime/the-police'
    @item.reconcile_tags
    # Note: not testing the order of the sections in this test, just testing
    # that the section is still present and not duplicated
    assert_equal ['crime', 'crime/the-police'], @item.sections.sort
  end

  test "can prepend tags" do
    # A bug in earlier versions of the mongoid library meant it would try to be
    # a little too clever dealing with arrays, and in so doing would process
    # modified arrays as $pushAll operators, breaking the array's ordering
    @item.tag_ids = ['crime', 'crime/the-police']
    @item.save
    @item.reload
    assert_equal @item.tag_ids, ['crime', 'crime/the-police']

    @item.tag_ids = ['crime/batman'] + @item.sections
    assert_equal @item.tag_ids, ['crime/batman', 'crime', 'crime/the-police']
    @item.save
    @item.reload
    assert_equal @item.tag_ids, ['crime/batman', 'crime', 'crime/the-police']
  end
end
