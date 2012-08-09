require "test_helper"

class ArtefactTagTest < ActiveSupport::TestCase

  TEST_SECTIONS = [
    ['crime', 'Crime'], ['crime/the-police', 'The Police'], ['crime/batman', 'Batman']
  ]
  TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

  setup do
    TEST_SECTIONS.each do |tag_id, title|
      TagRepository.put(:tag_id => tag_id, :tag_type => 'section', :title => title)
    end
    TEST_KEYWORDS.each do |tag_id, title|
      TagRepository.put(:tag_id => tag_id, :tag_type => 'keyword', :title => title)
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
    parent = TagRepository.load('crime')
    child = TagRepository.load('crime/batman')
    child.update_attributes parent_id: parent.tag_id

    a = FactoryGirl.create(:artefact)
    a.primary_section = child.tag_id
    a.reconcile_tag_ids

    assert_equal "#{parent.title}:#{child.title}", a.section
  end
end
