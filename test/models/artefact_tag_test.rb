require "test_helper"

class ArtefactTagTest < ActiveSupport::TestCase

  TEST_SECTIONS = [
    ['crime', 'Crime'], ['crime/the-police', 'The Police'], ['crime/batman', 'Batman']
  ]
  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

  setup do
    TEST_SECTIONS.each do |tag_id, title|
      FactoryGirl.create(:tag, :tag_id => tag_id, :tag_type => 'section', :title => title)
    end
    TEST_KEYWORDS.each do |tag_id, title|
      FactoryGirl.create(:tag, :tag_id => tag_id, :tag_type => 'keyword', :title => title)
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

  test "has legacy_sources tag collection" do
    ls1 = FactoryGirl.create(:tag, :tag_id => 'businesslink', :tag_type => 'legacy_source', :title => 'Business Link')
    ls2 = FactoryGirl.create(:tag, :tag_id => 'directgov', :tag_type => 'legacy_source', :title => 'Directgov')
    ls3 = FactoryGirl.create(:tag, :tag_id => 'dvla', :tag_type => 'legacy_source', :title => 'DVLA')

    a = FactoryGirl.build(:artefact)
    a.legacy_sources = ['businesslink', 'dvla']
    a.save

    a = Artefact.first
    assert_equal [ls1, ls3], a.legacy_sources
  end
end
