# require 'test_helper'
# module UberTaggable
#   module ClassMethods
#     def stores_tags_for(*keys)
#       keys.each { |k| attr_accessor k }
#       @tag_keys = keys
#       # store list of keys
#     end

#     def has_primary_tag_for(*keys)
#       # raise exception if there's a primary tag but we don't store tags
#       # raise "Bad tag" unless keys == @tag_keys
#       keys.each { |k| attr_accessor "primary_#{k.to_s.singularize}" }
#       @primary_tag_keys = keys
#       # store list of keys
#     end
#   end

#   def self.included(klass)
#     klass.extend         ClassMethods
#     klass.field          :tag_ids, type: String
#     klass.attr_protected :tags, :tag_ids
#   end

#   def expand_tags
#     # Process types of tags and drop into appropriate places
#   end

#   def reconcile_tags
#     puts @tag_keys.inspect
#     # Assemble primary tags
#     # Assemble other tags
#     # Dedupe
#   end

#   def tags
#     @tags ||= TagRepository.load_all_with_ids(tag_ids)
#   end

#   def save
#     reconcile_tags
#     parent
#   end
# end

# class Artefact
#   include UberTaggable

#   stores_tags_for :sections, :writing_teams, :propositions
#   has_primary_tag_for :sections
# end

# TEST_SECTIONS = [['crime', 'Crime'], ['crime/the-police', 'The Police'],
#                  ['crime/batman', 'Batman']]
# TEST_KEYWORDS = [['cheese', 'Cheese'], ['bacon', 'Bacon']]

# class ArtefactTagTest < ActiveSupport::TestCase

#   setup do
#     TEST_SECTIONS.each do |tag_id, title|
#       TagRepository.put(:tag_id => tag_id, :tag_type => 'section', :title => title)
#     end
#     TEST_KEYWORDS.each do |tag_id, title|
#       TagRepository.put(:tag_id => tag_id, :tag_type => 'keyword', :title => title)
#     end
#   end

#   test "can set sections" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.sections = ['crime', 'crime/the-police']
#     a.primary_section = 'crime'
#     a.reconcile_tags

#     assert_equal ['crime', 'crime/the-police'], a.tag_ids, 'Mismatched tags'
#     assert_equal ['crime', 'crime/the-police'], a.sections, 'Mismatched sections'

#     assert_equal 'Crime', a.section
#   end

#   test "can set subsection as primary section" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.sections = ['crime/the-police', 'crime']
#     a.primary_section = 'crime/the-police'
#     a.reconcile_tags
#     assert_equal 'Crime:The Police', a.section
#   end

#   test "cannot set non-existent sections" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     assert_raise RuntimeError do
#       a.sections = ['weevils']
#     end
#   end

#   test "can set primary section to the empty string" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.primary_section = 'crime'
#     a.primary_section = ''
#     assert_equal nil, a.primary_section
#   end

#   test "can set primary section to nil" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.primary_section = 'crime'
#     a.primary_section = nil
#     assert_equal nil, a.primary_section
#   end

#   test "cannot set non-section tags" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     assert_raise RuntimeError do
#       a.sections = ['crime', 'bacon']
#     end
#   end

#   test "can set no sections" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.sections = ['crime', 'crime/the-police']
#     a.sections = []
#     assert_equal [], a.sections

#     assert_equal '', a.section
#   end

#   test "setting sections doesn't break other tags" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.tag_ids = ['cheese', 'bacon']
#     a.sections = ['crime']
#     a.primary_section = 'crime'
#     a.reconcile_tags
#     assert_equal ['bacon', 'cheese', 'crime'], a.tag_ids.sort

#     assert_equal 'Crime', a.section
#   end

#   test "appending sections either works or raises an exception" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.sections = ['crime']
#     begin
#       a.sections << 'crime/the-police'
#     rescue RuntimeError
#       return  # If the sections list is frozen, that's ok
#     end
#     assert_equal ['crime', 'crime/the-police'], a.sections
#   end

#   test "setting primary section adds section to tags" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.sections = ['crime', 'crime/the-police']
#     a.primary_section = 'crime/batman'
#     a.reconcile_tags
#     assert_includes a.sections, 'crime/batman'
#   end

#   test "setting primary section to existing section works" do
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.sections = ['crime', 'crime/the-police']
#     a.primary_section = 'crime/the-police'
#     a.reconcile_tags
#     # Note: not testing the order of the sections in this test, just testing
#     # that the section is still present and not duplicated
#     assert_equal ['crime', 'crime/the-police'], a.sections.sort
#   end

#   test "can prepend tags" do
#     # A bug in earlier versions of the mongoid library meant it would try to be
#     # a little too clever dealing with arrays, and in so doing would process
#     # modified arrays as $pushAll operators, breaking the array's ordering
#     a = Artefact.create!(:slug => "a", :name => "a", :kind => "answer",
#                          :need_id => 1, :owning_app => 'x')
#     a.tag_ids = ['crime', 'crime/the-police']
#     a.save
#     a.reload
#     assert_equal a.tag_ids, ['crime', 'crime/the-police']

#     a.tag_ids = ['crime/batman'] + a.sections
#     assert_equal a.tag_ids, ['crime/batman', 'crime', 'crime/the-police']
#     a.save
#     a.reload
#     assert_equal a.tag_ids, ['crime/batman', 'crime', 'crime/the-police']
#   end
# end
