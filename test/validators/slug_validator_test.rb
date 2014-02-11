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

  def document_with_slug(slug, override_options = {})
    default_options = {
      name: "Test",
      slug: slug
    }
    Dummy.new(default_options.merge(override_options))
  end

  context "default slugs" do
    should "reject url paths" do
      refute document_with_slug("path/not-allowed").valid?
    end

    should "allow a normal slug" do
      assert document_with_slug("normal-slug").valid?
    end
  end

  context "Help pages" do
    should "must start with help/" do
      refute document_with_slug("test", kind: "help_page").valid?
      assert document_with_slug("help/test", kind: "help_page").valid?
    end
  end

  context "Inside government slugs" do
    should "allow slug starting government/" do
      refute document_with_slug("test", kind: "policy").valid?
      assert document_with_slug("government/test", kind: "policy").valid?
    end

    should "allow friendly_id suffixes to pass" do
      assert document_with_slug("government/policy/test--3", kind: "policy").valid?
    end
  end

  context "Specialist documents" do
    should "all url nested one level deep" do
      assert document_with_slug("some-finder/my-specialist-document", kind: "specialist-document").valid?
    end

    should "not allow deeper nesting" do
      refute document_with_slug("some-finder/my-specialist-document/not-allowed", kind: "specialist-document").valid?
    end
  end
end
