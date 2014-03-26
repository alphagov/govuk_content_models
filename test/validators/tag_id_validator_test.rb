require 'test_helper'
require 'tag_id_validator'

class TagIdValidatorTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field :tag_id, type: String
    field :parent_id, type: String

    validates_with TagIdValidator
  end

  should "permit a lower-case alphanumeric tag id" do
    dummy = Dummy.new(tag_id: "a-good-tag-id")
    assert dummy.valid?
  end

  should "not permit a tag id with spaces" do
    dummy = Dummy.new(tag_id: "this tag has spaces")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit a tag id with uppercase characters" do
    dummy = Dummy.new(tag_id: "CLEAN-ALL-THE-THINGS")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit a tag id with non-alphanumeric characters" do
    dummy = Dummy.new(tag_id: "a-t@g-!d")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit a tag id with underscores" do
    dummy = Dummy.new(tag_id: "tag_id_with_underscores")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit a tag id with a slash when no parent id present" do
    dummy = Dummy.new(tag_id: "a-tag-id/with-a-slash", parent_id: nil)
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "permit a tag id containing the parent id and a slash when the tag has a parent" do
    dummy = Dummy.new(tag_id: "parent-tag-id/child-tag-id", parent_id: "parent-tag-id")
    assert dummy.valid?
  end

  should "not permit a tag id where the parent id is missing from the slug" do
    dummy = Dummy.new(tag_id: "a-tag-id/with-a-slash", parent_id: "parent-tag-id")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)

    dummy = Dummy.new(tag_id: "child-tag-id", parent_id: "parent-tag-id")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit more than one slash in a tag id" do
    dummy = Dummy.new(tag_id: "parent-tag-id/more/than/one/slash", parent_id: "parent-tag-id")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

end
