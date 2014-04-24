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

  should "permit a child tag id containing a slash" do
    dummy = Dummy.new(tag_id: "parent-tag-id/child-tag-id", parent_id: 1)
    assert dummy.valid?
  end

  should "not permit a parent tag id containing a slash" do
    dummy = Dummy.new(tag_id: "an-invalid/parent-tag-id", parent_id: nil)
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit a child tag id with more than one slash" do
    dummy = Dummy.new(tag_id: "parent-tag-id/two/slashes", parent_id: 1)
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

  should "not permit a slash at the end of a tag id" do
    dummy = Dummy.new(tag_id: "parent-tag-id/")
    refute dummy.valid?
    assert dummy.errors.has_key?(:tag_id)
  end

end
