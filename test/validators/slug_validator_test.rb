require 'test_helper'

class SlugTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field "name", type: String
    field "slug", type: String
    field "kind", type: String

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true, slug: true
  end

  context "Slugs are checked" do
    should "validate slugs for normal documents" do
      record = Dummy.new(name: "Test", slug: "test")
      assert record.valid?
    end

    should "validate help pages as starting with /help" do
      record = Dummy.new(name: "Help 1", slug: "test", kind: "help_page")
      assert record.invalid?

      record.slug = "help/test"
      assert record.valid?
    end

    should "validate inside government slugs as containing /government" do
      record = Dummy.new(name: "Test 2", slug: "test", kind: "policy")
      assert record.invalid?

      record.slug = "government/test"
      assert record.valid?
    end

    should "allow friendly_id suffixes to pass" do
      record = Dummy.new(name: "Test 3", slug: "government/policy/test--3", kind: "policy")
      assert record.valid?
    end
  end
end
