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

    should "require a government prefix for Inside Government artefacts" do
      a = FactoryGirl.build(:artefact, slug: "slug", kind: "case_study")
      refute a.valid?
    end

    should "not require a government prefix for Detailed Guides" do
      a = FactoryGirl.build(:artefact, slug: "slug", kind: "detailed_guide")
      assert a.valid?
    end
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
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_id: 1, owning_app: "x")
    b = Artefact.create!(slug: "b", name: "b", kind: "place", need_id: 2, owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_id: 3, owning_app: "x")

    a.related_artefacts = [b, c]
    a.save!
    a.reload

    assert_equal [b, c], a.ordered_related_artefacts
  end

  test "should store and return related artefacts in order, even when not in natural order" do
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_id: 1, owning_app: "x")
    b = Artefact.create!(slug: "b", name: "b", kind: "place", need_id: 2, owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_id: 3, owning_app: "x")

    a.related_artefacts = [c, b]
    a.save!
    a.reload

    assert_equal [c, b], a.ordered_related_artefacts
  end

  test "should store and return related artefacts in order, with a scope" do
    a = Artefact.create!(slug: "a", name: "a", kind: "place", need_id: 1, owning_app: "x")
    b = Artefact.create!(state: "live", slug: "b", name: "b", kind: "place", need_id: 2, owning_app: "x")
    c = Artefact.create!(slug: "c", name: "c", kind: "place", need_id: 3, owning_app: "x")
    d = Artefact.create!(state: "live", slug: "d", name: "d", kind: "place", need_id: 3, owning_app: "x")

    a.related_artefacts = [d, c, b]
    a.save!
    a.reload

    assert_equal [d, b], a.ordered_related_artefacts(a.related_artefacts.where(state: "live"))
  end

  test "published_related_artefacts should return all non-publisher artefacts, but only published publisher artefacts" do
    # because currently only publisher has an idea of "published"

    parent = Artefact.create!(slug: "parent", name: "Parent", kind: "guide", owning_app: "x")

    a = Artefact.create!(slug: "a", name: "has no published editions", kind: "guide", owning_app: "publisher")
    Edition.create!(panopticon_id: a.id, title: "Unpublished", state: "draft")
    parent.related_artefacts << a

    b = Artefact.create!(slug: "b", name: "has a published edition", kind: "guide", owning_app: "publisher")
    Edition.create!(panopticon_id: b.id, title: "Published", state: "published")
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

  test "on save update metadata with associated publication" do
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
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

    assert_equal artefact.name, edition.title
    assert_equal artefact.section, edition.section

    artefact.name = "Babar"
    artefact.save

    edition.reload
    assert_equal artefact.name, edition.title
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
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
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
    assert_equal artefact.section, edition.section

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
      a = FactoryGirl.build(:artefact)
      assert ! a.need_extended_font
    end

    should "allow has_extended_chars to be set" do
      a = FactoryGirl.build(:artefact)
      a.need_extended_font = true
      assert a.need_extended_font
    end
  end

  context "returning json representation" do
    context "returning tags" do
      setup do
        FactoryGirl.create(:tag, :tag_type => 'section', :tag_id => 'crime', :title => 'Crime')
        FactoryGirl.create(:tag, :tag_type => 'section', :tag_id => 'justice', :title => 'Justice', :description => "All about justice")
        FactoryGirl.create(:tag, :tag_type => 'legacy_source', :tag_id => 'directgov', :title => 'Directgov')
        FactoryGirl.create(:tag, :tag_type => 'legacy_source', :tag_id => 'businesslink', :title => 'Business Link')

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
      end
    end
  end
end
