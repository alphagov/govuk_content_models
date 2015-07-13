require "test_helper"

class ArtefactTest < ActiveSupport::TestCase
  context "validating slug" do
    should "allow nice clean slugs" do
      a = FactoryGirl.build(:artefact, slug: "its-a-nice-day")
      assert a.valid?
    end

    should "not allow apostrophes in slugs" do
      a = FactoryGirl.build(:artefact, slug: "it's-a-nice-day")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow spaces in slugs" do
      a = FactoryGirl.build(:artefact, slug: "it is-a-nice-day")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "allow slashes in slugs when the namespace is 'done'" do
      a = FactoryGirl.build(:artefact, slug: "done/its-a-nice-day")
      assert a.valid?
    end

    should "not allow slashes in slugs when the namespace is not 'done'" do
      a = FactoryGirl.build(:artefact, slug: "something-else/its-a-nice-day")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "allow travel-advice to have a slug prefixed with 'foreign-travel-advice/'" do
      a = FactoryGirl.build(:artefact, slug: "foreign-travel-advice/aruba", kind: "travel-advice")
      assert a.valid?
    end

    should "not allow multiple slashes in travel-advice artefacts" do
      a = FactoryGirl.build(:artefact, slug: "foreign-travel-advice/aruba/foo", kind: "travel-advice")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow a foreign-travel-advice prefix for non-travel-advice artefacts" do
      a = FactoryGirl.build(:artefact, slug: "foreign-travel-advice/aruba", kind: "answer")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "allow a government prefix for Inside Government artefacts" do
      a = FactoryGirl.build(:artefact, slug: "government/slug", kind: "case_study")
      assert a.valid?
    end

    should "allow a government prefix and multiple path parts for Inside Government artefacts" do
      a = FactoryGirl.build(:artefact, slug: "government/something/somewhere/somehow/slug", kind: "case_study")
      assert a.valid?
    end

    should "not allow a government prefix with invalid path parts" do
      a = FactoryGirl.build(:artefact, slug: "government/SomeThing/some.where/somehow/slug", kind: "case_study")
      refute a.valid?
    end

    should "require a government prefix for Inside Government artefacts" do
      a = FactoryGirl.build(:artefact, slug: "slug", kind: "case_study")
      refute a.valid?
    end

    should "not require a government prefix for Detailed Guides" do
      a = FactoryGirl.build(:artefact, slug: "slug", kind: "detailed_guide")
      assert a.valid?
    end

    context "help page special case" do
      should "allow a help page to have a help/ prefix on the slug" do
        a = FactoryGirl.build(:artefact, :slug => "help/foo", :kind => "help_page")
        assert a.valid?
      end

      should "require a help page to have a help/ prefix on the slug" do
        a = FactoryGirl.build(:artefact, :slug => "foo", :kind => "help_page")
        refute a.valid?
        assert_equal 1, a.errors[:slug].count
      end

      should "not allow other kinds to have a help/ prefix" do
        a = FactoryGirl.build(:artefact, :slug => "help/foo", :kind => "answer")
        refute a.valid?
        assert_equal 1, a.errors[:slug].count
      end
    end
  end

  context "#need_ids" do
    should "be empty by default" do
      assert_empty FactoryGirl.build(:artefact).need_ids
    end

    should "do validations if nil" do
      artefact = FactoryGirl.create(:artefact, need_ids: ["100001"])
      artefact.need_ids = nil

      assert_nothing_raised { artefact.valid? }
    end

    should "filter out empty strings" do
      artefact = FactoryGirl.create(:artefact, need_ids: ["", "100002"])
      assert_equal ["100002"], artefact.reload.need_ids
    end

    should "store multiple needs related to an artefact" do
      artefact = FactoryGirl.create(:artefact, need_ids: ["100001", "100002"])
      assert_equal ["100001", "100002"], artefact.reload.need_ids
    end

    should "be six-digit integers" do
      artefact = FactoryGirl.build(:artefact, need_ids: ["B1231"])

      refute artefact.valid?
      assert_includes artefact.errors[:need_ids], "must be six-digit integer strings"
    end

    should "not validate need ids that were migrated from the singular need_id field" do
      artefact = FactoryGirl.create(:artefact)
      # simulate what happened during migration
      artefact.set(:need_ids, ['As an employer
                                I need to know which type of DBS check an employee needs
                                so that I can apply for the correct one'])

      artefact.need_ids << "100045"

      assert artefact.valid?
    end

    context "for backwards compatibility" do
      setup do
        @artefact = FactoryGirl.create(:artefact)
      end

      should "append to need_ids when need_id is assigned" do
        @artefact.need_id = "100045"

        assert_equal "100045", @artefact.need_id
        assert_includes @artefact.need_ids, "100045"
      end

      should "append to existing need_ids when need_id is assigned" do
        @artefact.set(:need_ids, ["100044"])
        @artefact.set(:need_id, "100044")

        @artefact.need_id = "100045"

        assert_equal "100045", @artefact.need_id
        assert_equal ["100044", "100045"], @artefact.need_ids
      end

      # this should only matter till the time we have both fields
      # need_id and need_ids. can delete this test once we unset need_id.
      should "keep need_ids unchanged when need_id is removed" do
        @artefact.set(:need_ids, ["100044", "100045"])
        @artefact.set(:need_id, "100044")

        @artefact.need_id = nil

        assert_equal nil, @artefact.need_id
        assert_equal ["100044", "100045"], @artefact.need_ids
      end
    end
  end

  context "validating paths and prefixes" do
    setup do
      @a = FactoryGirl.build(:artefact)
    end

    should "be valid when empty" do
      @a.paths = []
      @a.prefixes = []
      assert @a.valid?

      @a.paths = nil
      @a.prefixes = nil
      assert @a.valid?
    end

    should "be valid when set to array of absolute URL paths" do
      @a.paths = ["/foo.json"]
      @a.prefixes = ["/foo", "/bar"]
      assert @a.valid?
    end

    should "be invalid if an entry is not a valid absolute URL path" do
      [
        "not a URL path",
        "http://foo.example.com/bar",
        "bar/baz",
        "/foo/bar?baz=qux",
      ].each do |path|
        @a.paths = ["/foo.json", path]
        @a.prefixes = ["/foo", path]
        refute @a.valid?
        assert_equal 1, @a.errors[:paths].count
        assert_equal 1, @a.errors[:prefixes].count
      end
    end

    should "be invalid with consecutive or trailing slashes" do
      [
        "/foo//bar",
        "/foo/bar///",
        "//bar/baz",
        "//",
        "/foo/bar/",
      ].each do |path|
        @a.paths = ["/foo.json", path]
        @a.prefixes = ["/foo", path]
        refute @a.valid?
        assert_equal 1, @a.errors[:paths].count
        assert_equal 1, @a.errors[:prefixes].count
      end
    end

    should "skip validating these if they haven't changed" do
      # This validation can be expensive, so skip it where unnecessary.
      @a.paths = ["foo"]
      @a.prefixes = ["bar"]
      @a.save :validate => false

      assert @a.valid?
    end
  end

  should "validate redirect_url" do
    artefact = FactoryGirl.create(:artefact)

    artefact.redirect_url = "foobar"
    refute artefact.valid?

    artefact.redirect_url = "/foobar"
    assert artefact.valid?

    artefact.redirect_url = "http://foo.bar/"
    refute artefact.valid?
  end

  test "should translate kind into internally normalised form" do
    a = Artefact.new(kind: "benefit / scheme")
    a.normalise
    assert_equal "programme", a.kind
  end

  test "should not translate unknown kinds" do
    a = Artefact.new(kind: "other")
    a.normalise
    assert_equal "other", a.kind
  end

  test "should store and return related artefacts in order" do
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_ids: ["100001"], owning_app: "x")
    b = Artefact.create!(slug: "b", name: "b", kind: "place", need_ids: ["100001"], owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_ids: ["100001"], owning_app: "x")

    a.related_artefacts = [b, c]
    a.save!
    a.reload

    assert_equal [b, c], a.ordered_related_artefacts
  end

  test "should store and return related artefacts in order, even when not in natural order" do
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_ids: ["100001"], owning_app: "x")
    b = Artefact.create!(slug: "b", name: "b", kind: "place", need_ids: ["100001"], owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_ids: ["100001"], owning_app: "x")

    a.related_artefacts = [c, b]
    a.save!
    a.reload

    assert_equal [c, b], a.ordered_related_artefacts
  end

  test "should store and return related artefacts in order, with a scope" do
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_ids: ["100001"], owning_app: "x")
    b = Artefact.create!(state: "live", slug: "b", name: "b", kind: "place", need_ids: ["100001"], owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_ids: ["100001"], owning_app: "x")
    d = Artefact.create!(state: "live", slug: "d", name: "d", kind: "place", need_ids: ["100001"], owning_app: "x")

    a.related_artefacts = [d, c, b]
    a.save!
    a.reload

    assert_equal [d, b], a.ordered_related_artefacts(a.related_artefacts.where(state: "live"))
  end

  test "published_related_artefacts should return all non-publisher artefacts, but only published publisher artefacts" do
    # because currently only publisher has an idea of "published"

    parent = Artefact.create!(slug: "parent", name: "Parent", kind: "guide", owning_app: "x")

    a = Artefact.create!(slug: "a", name: "has no published editions", kind: "guide", owning_app: "publisher")
    GuideEdition.create!(panopticon_id: a.id, title: "Unpublished", state: "draft")
    parent.related_artefacts << a

    b = Artefact.create!(slug: "b", name: "has a published edition", kind: "guide", owning_app: "publisher")
    GuideEdition.create!(panopticon_id: b.id, title: "Published", state: "published")
    parent.related_artefacts << b

    c = Artefact.create!(slug: "c", name: "not a publisher artefact", kind: "place", owning_app: "x")
    parent.related_artefacts << c
    parent.save!

    assert_equal [b.slug, c.slug], parent.published_related_artefacts.map(&:slug)
  end

  test "should raise a not found exception if the slug doesn't match" do
    assert_raise Mongoid::Errors::DocumentNotFound do
      Artefact.from_param("something-fake")
    end
  end

  should "update the edition's slug when a draft artefact is saved" do
    artefact = FactoryGirl.create(:draft_artefact)
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id)

    artefact.slug = "something-something-draft"
    artefact.save!

    edition.reload
    assert_equal artefact.slug, edition.slug
  end

  should "not update the edition's slug when a live artefact is saved" do
    artefact = FactoryGirl.create(:live_artefact, slug: "something-something-live")
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id, slug: "something-else")

    artefact.save!

    edition.reload
    assert_equal "something-else", edition.slug
  end

  should "not update the edition's slug when an archived artefact is saved" do
    artefact = FactoryGirl.create(:live_artefact, slug: "something-something-live")
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id, slug: "something-else")

    artefact.state = 'archived'
    artefact.save!

    edition.reload
    assert_equal "something-else", edition.slug
  end

  test "should not let you edit the slug if the artefact is live" do
    artefact = FactoryGirl.create(:artefact,
        slug: "too-late-to-edit",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
        state: "live"
    )

    artefact.slug = "belated-correction"
    refute artefact.save

    assert_equal "too-late-to-edit", artefact.reload.slug
  end

  # should continue to work in the way it has been:
  # i.e. you can edit everything but the name/title for published content in panop
  test "on save title should not be applied to already published content" do
    FactoryGirl.create(:live_tag, tag_id: "test-section", title: "Test section", tag_type: "section")
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        primary_section: "test-section",
        sections: ["test-section"],
        department: "Test dept",
        owning_app: "publisher",
    )

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})
    edition.state = "published"
    edition.save!

    assert_equal artefact.name, edition.title

    artefact.name = "Babar"
    artefact.save

    edition.reload
    assert_not_equal artefact.name, edition.title
  end

  test "should indicate when any editions have been published for this artefact" do
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
    )
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1, {})

    refute artefact.any_editions_published?

    edition.state = "published"
    edition.save!

    assert artefact.any_editions_published?
  end

  test "should have a specialist_body field present for markdown content" do
    artefact = Artefact.create!(slug: "parent", name: "Harry Potter", kind: "guide", owning_app: "x")
    refute_includes artefact.attributes, "specialist_body"

    artefact.specialist_body = "Something wicked this way comes"
    assert_includes artefact.attributes, "specialist_body"
    assert_equal "Something wicked this way comes", artefact.specialist_body
  end

  test "should have 'video' as a supported FORMAT" do
    assert_includes Artefact::FORMATS, "video"
  end

  test "should find the default owning_app for a format" do
    assert_equal "publisher", Artefact.default_app_for_format("guide")
  end

  test "should allow creation of artefacts with 'video' as the kind" do
    artefact = Artefact.create!(slug: "omlette-du-fromage", name: "Omlette du fromage", kind: "video", owning_app: "Dexter's Lab")

    refute artefact.nil?
    assert_equal "video", artefact.kind
  end

  test "should archive all editions when archived" do
    artefact = FactoryGirl.create(:artefact, state: "live")
    editions = ["draft", "ready", "published", "archived"].map { |state|
      FactoryGirl.create(:programme_edition, panopticon_id: artefact.id, state: state)
    }
    user1 = FactoryGirl.create(:user)

    artefact.update_attributes_as(user1, state: "archived")
    artefact.save!

    editions.each &:reload
    editions.each do |edition|
      assert_equal "archived", edition.state
    end
    # remove the previously already archived edition, as no note will have been added
    editions.pop
    editions.each do |edition|
      assert_equal "Artefact has been archived. Archiving this edition.", edition.actions.first.comment
    end
  end

  test "should restrict what attributes can be updated on an edition that has an archived artefact" do
    artefact = FactoryGirl.create(:artefact, state: "live")
    edition = FactoryGirl.create(:programme_edition, panopticon_id: artefact.id, state: "published")
    artefact.state = "archived"
    artefact.save
    assert_raise RuntimeError do
      edition.update_attributes({state: "archived", title: "Shabba", slug: "do-not-allow"})
    end
  end

  should "not remove double dashes in a Detailed Guide slug" do
    a = FactoryGirl.create(:artefact, slug: "duplicate-slug--1", kind: "detailed_guide")
    a.reload

    assert_equal "duplicate-slug--1", a.slug
  end

  context "artefact language" do
    should "return english by default" do
      a = FactoryGirl.create(:artefact)

      assert_equal 'en', a.language
    end

    should "accept welsh language" do
      a = FactoryGirl.build(:artefact)
      a.language = 'cy'
      a.save

      a = Artefact.first
      assert_equal 'cy', a.language
    end

    should "reject a language which is not english or welsh" do
      a = FactoryGirl.build(:artefact)
      a.language = 'pirate'

      assert ! a.valid?
    end

    should "has has_extended_chars field set to false by default" do
      a = Artefact.new
      assert_equal false, a.need_extended_font
    end

    should "allow has_extended_chars to be set" do
      a = FactoryGirl.build(:artefact)
      a.need_extended_font = true
      a.save

      a = Artefact.first
      assert_equal true, a.need_extended_font
    end
  end

  context "returning json representation" do
    context "returning tags" do
      setup do
        FactoryGirl.create(:live_tag, :tag_type => 'section', :tag_id => 'crime', :title => 'Crime')
        FactoryGirl.create(:live_tag, :tag_type => 'section', :tag_id => 'justice', :title => 'Justice', :description => "All about justice")
        FactoryGirl.create(:live_tag, :tag_type => 'legacy_source', :tag_id => 'directgov', :title => 'Directgov')
        FactoryGirl.create(:live_tag, :tag_type => 'legacy_source', :tag_id => 'businesslink', :title => 'Business Link')

        @a = FactoryGirl.create(:artefact, :slug => 'fooey')
      end

      should "return empty array of tags and tag_ids" do
        hash = @a.as_json

        assert_equal [], hash['tag_ids']
        assert_equal [], hash['tags']
      end

      context "for an artefact with tags" do
        setup do
          @a.sections = ['justice']
          @a.legacy_sources = ['businesslink']
          @a.save!
        end

        should "return an array of tag_id strings in tag_ids" do
          hash = @a.as_json

          assert_equal ['justice', 'businesslink'], hash['tag_ids']
        end

        should "return an array of tag objects in tags" do
          hash = @a.as_json

          expected = [
            {
              :id => 'justice',
              :title => 'Justice',
              :type => 'section',
              :description => 'All about justice',
              :short_description => nil
            },
            {
              :id => 'businesslink',
              :title => 'Business Link',
              :type => 'legacy_source',
              :description => nil,
              :short_description => nil
            }
          ]
          assert_equal expected, hash['tags']
        end

        should "omit non-existent tags referenced from the tag_ids array" do
          @a.tag_ids << 'batman'
          hash = @a.as_json

          assert_equal %w(justice businesslink), hash['tags'].map {|t| t[:id] }
        end
      end
    end
  end

  context "artefact related external links" do
    should "have none by default" do
      artefact = FactoryGirl.create(:artefact)
      assert_equal 0, artefact.external_links.length
    end

    should "contain the title and URL of the link" do
      artefact = FactoryGirl.create(:artefact)
      artefact.external_links << ArtefactExternalLink.new(:title => "Foo", :url => "http://bar.com")
      assert_equal 1, artefact.external_links.length
      assert_equal "Foo", artefact.external_links.first.title
    end
  end

  should "have an archived? helper method" do
    published_artefact = FactoryGirl.create(:artefact, :slug => "scooby", :state => "live")
    archived_artefact = FactoryGirl.create(:artefact, :slug => "doo", :state => "archived")

    refute published_artefact.archived?
    assert archived_artefact.archived?
  end

  should "have a related_items method which discards artefacts that are archived or completed transactions" do
    generic = FactoryGirl.create(:artefact, slug: "generic")
    archived = FactoryGirl.create(:artefact, :slug => "archived", :state => "archived")
    completed = FactoryGirl.create(:artefact, slug: "completed-transaction", kind: "completed_transaction")

    assert_equal [generic], Artefact.relatable_items
  end

  context "related artefacts grouped by section tags" do
    setup do
      FactoryGirl.create(:live_tag, :tag_id => "fruit", :tag_type => 'section', :title => "Fruit")
      FactoryGirl.create(:live_tag, :tag_id => "fruit/simple", :tag_type => 'section', :title => "Simple fruits", :parent_id => "fruit")
      FactoryGirl.create(:live_tag, :tag_id => "fruit/aggregate", :tag_type => 'section', :title => "Aggregrate fruits", :parent_id => "fruit")
      FactoryGirl.create(:live_tag, :tag_id => "vegetables", :tag_type => 'section', :title => "Vegetables")

      @artefact = Artefact.create!(slug: "apple", name: "Apple", sections: [], kind: "guide", need_ids: ["100001"], owning_app: "x")
    end

    context "when related items are present in all groups" do
      setup do
        @artefact.sections = ["fruit/simple"]

        @artefact.related_artefacts = [
          Artefact.create!(slug: "pear", name: "Pear", kind: "guide", sections: ["fruit/simple"], need_ids: ["100001"], owning_app: "x"),
          Artefact.create!(slug: "pineapple", name: "Pineapple", kind: "guide", sections: ["fruit/aggregate"], need_ids: ["100001"], owning_app: "x"),
          Artefact.create!(slug: "broccoli", name: "Broccoli", kind: "guide", sections: ["vegetables"], need_ids: ["100001"], owning_app: "x")
        ]
        @artefact.save!
        @artefact.reload
      end

      should "return a hash of artefacts in the same subsection" do
        artefacts = @artefact.related_artefacts_grouped_by_distance
        assert_equal ["pear"], artefacts['subsection'].map(&:slug)
      end

      should "return a hash of other artefacts in the same parent section" do
        artefacts = @artefact.related_artefacts_grouped_by_distance
        assert_equal ["pineapple"], artefacts['section'].map(&:slug)
      end

      should "return a hash of artefacts in other sections" do
        artefacts = @artefact.related_artefacts_grouped_by_distance
        assert_equal ["broccoli"], artefacts['other'].map(&:slug)
      end

      should "return related artefacts in order, with a scope" do
        a = Artefact.create!(state: "live", slug: "a", name: "a", kind: "place", need_ids: ["100001"], owning_app: "x")
        b = Artefact.create!(slug: "b", name: "b", kind: "place", need_ids: ["100001"], owning_app: "x")
        c = Artefact.create!(state: "live", slug: "c", name: "c", kind: "place", need_ids: ["100001"], owning_app: "x")

        @artefact.related_artefacts = [c,b,a]
        @artefact.save!
        @artefact.reload

        assert_equal [c, a], @artefact.related_artefacts_grouped_by_distance(@artefact.related_artefacts.where(state: "live"))["other"]
      end
    end

    should "return an empty array for a group with no related artefacts" do
      # @artefact with no related items created in setup block

      assert_equal [], @artefact.related_artefacts_grouped_by_distance["subsection"]
      assert_equal [], @artefact.related_artefacts_grouped_by_distance["section"]
      assert_equal [], @artefact.related_artefacts_grouped_by_distance["other"]
    end

    should "return all related artefacts in 'other' when an artefact has no sections" do
      @artefact.related_artefacts = [
        Artefact.create!(slug: "pear", name: "Pear", kind: "guide", sections: ["fruit/simple"], need_ids: ["100001"], owning_app: "x"),
        Artefact.create!(slug: "banana", name: "Banana", kind: "guide", sections: ["fruit/simple"], need_ids: ["100001"], owning_app: "x")
      ]

      assert_equal [], @artefact.related_artefacts_grouped_by_distance["subsection"]
      assert_equal [], @artefact.related_artefacts_grouped_by_distance["section"]
      assert_equal ["pear", "banana"], @artefact.related_artefacts_grouped_by_distance["other"].map(&:slug)
    end
  end
end
