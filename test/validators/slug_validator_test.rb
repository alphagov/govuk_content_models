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

    should "allow consecutive dashes in a slug" do
      # Gems like friendly_id use -- to de-dup slug collisions
      assert document_with_slug("normal-slug--1").valid?
    end

    should "allow a done page slug" do
      assert document_with_slug("done/normal-slug").valid?
    end
  end

  context "Foreign travel advice pages" do
    should "allow a travel-advice page to start with 'foreign-travel-advice/'" do
      assert document_with_slug("foreign-travel-advice/aruba", kind: "travel-advice").valid?
    end

    should "not allow other types to start with 'foreign-travel-advice/'" do
      refute document_with_slug("foreign-travel-advice/aruba", kind: "answer").valid?
    end
  end

  context "Help pages" do
    should "must start with help/" do
      refute document_with_slug("test", kind: "help_page").valid?
      assert document_with_slug("help/test", kind: "help_page").valid?
    end

    should "not allow non-help pages to start with help/" do
      refute document_with_slug("help/test", kind: "answer").valid?
    end
  end

  context "Inside government slugs" do
    should "allow slug starting government/" do
      refute document_with_slug("test", kind: "policy").valid?
      assert document_with_slug("government/test", kind: "policy").valid?
    end

    should "allow abritrarily deep slugs" do
      assert document_with_slug("government/test/foo", kind: "policy").valid?
      assert document_with_slug("government/test/foo/bar", kind: "policy").valid?
    end

    should "allow . in slugs" do
      assert document_with_slug("government/world-location-news/221033.pt", kind: "news_story").valid?
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

  context "Specialist sector browse pages" do
    should "allow a single path part" do
      assert document_with_slug("oil-and-gas", kind: "specialist_sector").valid?
    end

    should "allow two path parts" do
      assert document_with_slug("oil-and-gas/fields-and-wells", kind: "specialist_sector").valid?
    end

    should "not allow three path parts" do
      refute document_with_slug("oil-and-gas/fields-and-wells/development", kind: "specialist_sector").valid?
    end

    should "not allow invalid path segments" do
      refute document_with_slug("oil-and-gas/not.a.valid.slug", kind: "specialist_sector").valid?
    end
  end
end
