require "test_helper"

class Edition
  def update_in_search_index
  end
end

class EditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  def template_answer(version_number = 1)
    artefact = FactoryGirl.create(:artefact,
        kind: "answer",
        name: "Foo bar",
        # primary_section: "test-section",
        # sections: ["test-section"],
        # department: "Test dept",
        owning_app: "publisher")

    AnswerEdition.create(state: "ready", slug: "childcare", panopticon_id: artefact.id,
      title: "Child care stuff", body: "Lots of info", version_number: version_number)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish
    answer.save
    answer
  end

  def template_transaction
    artefact = FactoryGirl.create(:artefact)
    TransactionEdition.create(title: "One", introduction: "introduction",
      more_information: "more info", panopticon_id: @artefact.id, slug: "childcare")
  end

  def template_unpublished_answer(version_number = 1)
    template_answer(version_number)
  end

  test "it must have a title" do
    a = LocalTransactionEdition.new
    refute a.valid?
    assert a.errors[:title].any?
  end

  test "it should give a friendly (legacy supporting) description of its format" do
    a = LocalTransactionEdition.new
    assert_equal "LocalTransaction", a.format
  end

  test "it should be able to find its siblings" do
    @artefact2 = FactoryGirl.create(:artefact)
    g1 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g2 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact2.id, version_number: 1)
    g3 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)
    assert_equal [], g2.siblings.to_a
    assert_equal [g3], g1.siblings.to_a
  end

  test "it should be able to find its previous siblings" do
    @artefact2 = FactoryGirl.create(:artefact)    
    g1 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 1)
    g2 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact2.id, version_number: 1)
    g3 = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, version_number: 2)

    assert_equal [], g1.previous_siblings.to_a
    assert_equal [g1], g3.previous_siblings.to_a
  end

  test "A programme should have default parts" do
    programme = FactoryGirl.create(:programme_edition, panopticon_id: @artefact.id)
    assert_equal programme.parts.count, ProgrammeEdition::DEFAULT_PARTS.length
  end

  test "it should build a clone" do
    edition = FactoryGirl.create(:guide_edition,
                                  state: "published",
                                  panopticon_id: @artefact.id,
                                  version_number: 1,
                                  department: "Test dept",
                                  overview: "I am a test overview",
                                  alternative_title: "Alternative test title")
    clone_edition = edition.build_clone
    assert_equal clone_edition.department, "Test dept"
    assert_equal clone_edition.section, "test:subsection test"
    assert_equal clone_edition.overview, "I am a test overview"
    assert_equal clone_edition.alternative_title, "Alternative test title"
    assert_equal clone_edition.version_number, 2
  end

  test "cloning can only occur from a published edition" do
    edition = FactoryGirl.create(:guide_edition,
                                  panopticon_id: @artefact.id,
                                  version_number: 1)
    assert_raise(RuntimeError) do
      edition.build_clone
    end
  end

  test "cloning can only occur from a published edition with no subsequent in progress siblings" do
    edition = FactoryGirl.create(:guide_edition,
                                  panopticon_id: @artefact.id,
                                  state: "published",
                                  version_number: 1)

    FactoryGirl.create(:guide_edition,
                        panopticon_id: @artefact.id,
                        state: "draft",
                        version_number: 2)

    assert_raise(RuntimeError) do
      edition.build_clone
    end
  end

  test "cloning from an earlier edition should give you a safe version number" do
    edition = FactoryGirl.create(:guide_edition,
                                  state: "published",
                                  panopticon_id: @artefact.id,
                                  version_number: 1)
    edition_two = FactoryGirl.create(:guide_edition,
                                  state: "published",
                                  panopticon_id: @artefact.id,
                                  version_number: 2)

    clone1 = edition.build_clone
    assert_equal clone1.version_number, 3
  end

# test cloning into different edition types
  test "Cloning from GuideEdition into AnswerEdition" do
    edition = FactoryGirl.create(
        :guide_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title",
        video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ"
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal new_edition.class, AnswerEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
    assert_equal new_edition.whole_body, edition.whole_body
  end

  test "Cloning from ProgrammeEdition into AnswerEdition" do
    edition = FactoryGirl.create(
        :programme_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title"
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal new_edition.class, AnswerEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
    assert_equal new_edition.whole_body, edition.whole_body
  end

  test "Cloning from TransactionEdition into AnswerEdition" do
    edition = FactoryGirl.create(
        :transaction_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title",
        more_information: "More information",
        alternate_methods: "Alternate methods"
    )
    new_edition = edition.build_clone AnswerEdition

    assert_equal new_edition.class, AnswerEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
    assert_equal new_edition.whole_body, edition.whole_body
  end

  test "Cloning from AnswerEdition into TransactionEdition" do
    edition = FactoryGirl.create(
        :answer_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title",
        body: "Test body"
    )
    new_edition = edition.build_clone TransactionEdition

    assert_equal new_edition.class, TransactionEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
    assert_equal new_edition.more_information, "Test body"
  end

  test "Cloning from GuideEdition into TransactionEdition" do
    edition = FactoryGirl.create(
        :guide_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title",
        video_url: "http://www.youtube.com/watch?v=dQw4w9WgXcQ"
    )
    new_edition = edition.build_clone TransactionEdition

    assert_equal new_edition.class, TransactionEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
    assert_equal new_edition.more_information, edition.whole_body
  end

  test "Cloning from ProgrammeEdition into TransactionEdition" do
    edition = FactoryGirl.create(
        :programme_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title"
    )
    new_edition = edition.build_clone TransactionEdition

    assert_equal new_edition.class, TransactionEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
    assert_equal new_edition.more_information, edition.whole_body
  end

  test "Cloning from AnswerEdition into GuideEdition" do
    edition = FactoryGirl.create(
        :answer_edition,
        state: "published",
        panopticon_id: @artefact.id,
        version_number: 1,
        department: "Test dept",
        overview: "I am a test overview",
        alternative_title: "Alternative test title"
    )
    new_edition = edition.build_clone GuideEdition

    assert_equal new_edition.class, GuideEdition
    assert_equal new_edition.version_number, 2
    assert_equal new_edition.panopticon_id, @artefact.id.to_s
    assert_equal new_edition.state, "lined_up"
    assert_equal new_edition.department, "Test dept"
    assert_equal new_edition.overview, "I am a test overview"
    assert_equal new_edition.alternative_title, "Alternative test title"
  end

  test "Cloning between types with parts" do
    edition = FactoryGirl.create(:programme_edition_with_multiple_parts,
                                 panopticon_id: @artefact.id,
                                 state: "published",
                                 version_number: 1,
                                 overview: "I am a shiny programme",
                                 )
    new_edition = edition.build_clone GuideEdition

    assert_equal(new_edition.parts.map {|part| part.title },
                 edition.parts.map {|part| part.title })
    assert_equal 7, new_edition.parts.size #there are 5 'default' parts plus an additional two created by the factory
  end

  # Mongoid 2.x marks array fields as dirty whenever they are accessed.
  # See https://github.com/mongoid/mongoid/issues/2311
  # This behaviour has been patched in lib/mongoid/monkey_patches.rb
  # in order to prevent workflow validation failures for editions
  # with array fields.
  #
  test "editions with array fields should accurately track changes" do
    bs = FactoryGirl.create(:business_support_edition, sectors: [])
    assert_empty bs.changes
    bs.sectors
    assert_empty bs.changes
    bs.sectors << 'manufacturing'
    assert_equal ['sectors'], bs.changes.keys
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert dummy_publication.published?
    assert_equal dummy_publication, Edition.find_and_identify("childcare", "")
  end

  test "edition finder should return the latest edition when asked" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert_equal 2, Edition.where(slug: dummy_publication.slug).count
    found_edition = Edition.find_and_identify("childcare", "latest")
    assert_equal second_publication.version_number, found_edition.version_number
  end

  test "a publication should not have a video" do
    dummy_publication = template_published_answer
    assert !dummy_publication.has_video?
  end

  test "should create a publication based on data imported from panopticon" do
    section = FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        department: "Test dept",
        owning_app: "publisher",
    )
    artefact.primary_section = section.tag_id
    artefact.save!

    a = Artefact.find(artefact.id)

    assert_equal section.tag_id, artefact.primary_section.tag_id
    assert_equal section.title, artefact.primary_section.title
    user = User.create

    publication = Edition.find_or_create_from_panopticon_data(artefact.id, user, {})

    assert_kind_of AnswerEdition, publication
    assert_equal artefact.name, publication.title
    assert_equal artefact.id.to_s, publication.panopticon_id.to_s
    assert_equal section.title, publication.section
    assert_equal artefact.department, publication.department
  end

  # TODO: come back and remove this one.
  test "should not change edition name if published" do
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        department: "Test dept",
        owning_app: "publisher",
    )

    guide = FactoryGirl.create(:guide_edition,
      panopticon_id: artefact.id,
      title: "Original title",
      slug: "original-title"
    )
    guide.state = "ready"
    guide.save!
    User.create(name: "Winston").publish(guide, comment: "testing")
    artefact.name = "New title"
    artefact.primary_section = "test-section"
    artefact.save

    assert_equal "Original title", guide.reload.title
    assert_equal "Test section", guide.reload.section
  end

  test "should not change edition metadata if archived" do
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

    guide = FactoryGirl.create(:guide_edition,
      panopticon_id: artefact.id,
      title: "Original title",
      slug: "original-title",
      state: "archived"
    )
    artefact.slug = "new-slug"
    artefact.save

    assert_not_equal "new-slug", guide.reload.slug
  end

  test "should scope publications by assignee" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(status: 200, body: "{}", headers: {})

    a, b = 2.times.map { FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id) }

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a, bob)
    alice.assign(a, charlie)
    alice.assign(b, bob)

    assert_equal [b], Edition.assigned_to(bob).to_a
  end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = AnswerEdition.where(slug: "childcare").first

    assert_equal loaded_answer, dummy_answer
    assert ! dummy_answer.can_destroy?
    assert_raise (Workflow::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "cannot delete a published publication with a new draft edition" do
    dummy_answer = template_published_answer

    new_edition = dummy_answer.build_clone
    new_edition.body = "Two"
    dummy_answer.save

    assert_raise (Edition::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "can delete a publication that has not been published" do
    dummy_answer = template_unpublished_answer
    dummy_answer.destroy

    loaded_answer = AnswerEdition.where(slug: dummy_answer.slug).first
    assert_nil loaded_answer
  end

  test "should also delete associated artefact" do
    
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1, {})

    assert_difference "Artefact.count", -1 do
      edition.destroy
    end
  end

  test "should not delete associated artefact if there are other editions of this publication" do
    
    FactoryGirl.create(:tag, tag_id: "test-section", title: "Test section", tag_type: "section")
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(@artefact.id, user1, {})
    edition.update_attribute(:state, "published")

    edition.reload
    second_edition = edition.build_clone
    second_edition.save!

    assert_no_difference "Artefact.count" do
      second_edition.destroy
    end
  end

  test "should scope publications assigned to nobody" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(status: 200, body: "{}", headers: {})

    a, b = 2.times.map { |i| GuideEdition.create!(panopticon_id: @artefact.id, title: "Guide #{i}", slug: "guide-#{i}") }

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }

    alice.assign(a, bob)
    a.reload
    assert_equal bob, a.assigned_to

    alice.assign(a, charlie)
    a.reload
    assert_equal charlie, a.assigned_to

    assert_equal 2, Edition.count
    assert_equal [b], Edition.assigned_to(nil).to_a
    assert_equal [], Edition.assigned_to(bob).to_a
    assert_equal [a], Edition.assigned_to(charlie).to_a
  end

  test "given multiple editions, can return the most recent published edition" do
    
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, slug: "hedgehog-topiary", state: "published")

    second_edition = edition.build_clone
    edition.update_attribute(:state, "archived")
    second_edition.update_attribute(:state, "published")

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, "draft")

    assert_equal edition.published_edition, second_edition
  end

  test "editions, by default, return their title for use in the admin-interface lists of publications" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_equal edition.title, edition.admin_list_title
  end

  test "editions can have notes stored for the history tab" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    user = User.new
    assert edition.new_action(user, "note", comment: "Something important")
  end

  test "status should not be affected by notes" do
    user = User.create(name: "bob")
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.new_action(user, Action::APPROVE_REVIEW)
    edition.new_action(user, Action::NOTE, comment: "Something important")

    assert_equal Action::APPROVE_REVIEW, edition.latest_status_action.request_type
  end

  test "should have no assignee by default" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_nil edition.assigned_to
  end

  test "should be assigned to the last assigned recipient" do
    alice = User.create(name: "alice")
    bob = User.create(name: "bob")
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    alice.assign(edition, bob)
    assert_equal bob, edition.assigned_to
  end

  test "new edition should have an incremented version number" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    assert_equal edition.version_number + 1, new_edition.version_number
  end

  test "new edition should have an empty list of actions" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    assert_equal [], new_edition.actions
  end

  test "new editions should have the same text when created" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map {|p| p.body }.join(" ")
    assert_equal original_text, new_text
  end

  test "changing text in a new edition should not change text in old edition" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, panopticon_id: @artefact.id, state: "published")
    new_edition = edition.build_clone
    new_edition.parts.first.body = "Some other version text"
    original_text = edition.parts.map {|p| p.body }.join(" ")
    new_text = new_edition.parts.map {|p| p.body }.join(" ")
    assert_not_equal original_text, new_text
  end

  test "a new guide has no published edition" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    assert_nil GuideEdition.where(state: "published", panopticon_id: guide.panopticon_id).first
  end

  test "an edition of a guide can be published" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.publish
    assert_not_nil GuideEdition.where(state: "published", panopticon_id: edition.panopticon_id).first
  end

  test "when an edition of a guide is published, all other published editions are archived" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

    user = User.create name: "bob"
    user.publish edition, comment: "First publication"

    second_edition = edition.build_clone
    second_edition.update_attribute(:state, "ready")
    second_edition.save!
    user.publish second_edition, comment: "Second publication"

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, "ready")
    third_edition.save!
    user.publish third_edition, comment: "Third publication"

    edition.reload
    assert edition.archived?

    second_edition.reload
    assert second_edition.archived?

    assert_equal 2, GuideEdition.where(panopticon_id: edition.panopticon_id, state: "archived").count
  end

  test "edition can return latest status action of a specified request type" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    user = User.create(name: "George")
    user.request_review edition, comment: "Requesting review"

    assert_equal edition.actions.size, 1
    assert edition.latest_status_action(Action::REQUEST_REVIEW).present?
  end

  test "a published edition can't be edited" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    edition.title = "My New Title"

    assert ! edition.save
    assert_equal ["Published editions can't be edited"], edition.errors[:base]
  end

  test "edition's publish history is recorded" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

    user = User.create name: "bob"
    user.publish edition, comment: "First publication"

    second_edition = edition.build_clone
    second_edition.update_attribute(:state, "ready")
    second_edition.save!
    user.publish second_edition, comment: "Second publication"

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, "ready")
    third_edition.save!
    user.publish third_edition, comment: "Third publication"

    edition.reload
    assert edition.actions.where("request_type" => "publish")

    second_edition.reload
    assert second_edition.actions.where("request_type" => "publish")

    third_edition.reload
    assert third_edition.actions.where("request_type" => "publish")
    assert third_edition.published?
  end


 test "a series with all editions published should not have siblings in progress" do
   edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")

   user = User.create name: "bob"
   user.publish edition, comment: "First publication"

   new_edition = edition.build_clone
   new_edition.state = "ready"
   new_edition.save!
   user.publish new_edition, comment: "Second publication"

   edition = edition.reload

   assert_nil edition.sibling_in_progress
  end

  test "a series with one published and one draft edition should have a sibling in progress" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    edition.save!

    user = User.create name: "bob"
    user.publish edition, comment: "First publication"

    new_edition = edition.build_clone
    new_edition.save!

    edition = edition.reload

    assert_not_nil edition.sibling_in_progress
    assert_equal new_edition.version_number, edition.sibling_in_progress
  end

  test "a new guide edition with multiple parts creates a full diff when published" do
    user = User.create name: "Roland"

    edition_one = GuideEdition.new(title: "One", slug: "one", panopticon_id: @artefact.id)
    edition_one.parts.build title: "Part One", body:"Never gonna give you up", slug: "part-one"
    edition_one.parts.build title: "Part Two", body:"NYAN NYAN NYAN NYAN", slug: "part-two"
    edition_one.save!

    edition_one.state = :ready
    user.publish edition_one, comment: "First edition"

    edition_two = edition_one.build_clone
    edition_two.save!
    edition_two.parts.first.update_attribute :title, "Changed Title"
    edition_two.parts.first.update_attribute :body, "Never gonna let you down"

    edition_two.state = :ready
    user.publish edition_two, comment: "Second edition"

    publish_action = edition_two.actions.where(request_type: "publish").last

    assert_equal "{\"# Part One\" >> \"# Changed Title\"}\n\n{\"Never gonna give you up\" >> \"Never gonna let you down\"}\n\n# Part Two\n\nNYAN NYAN NYAN NYAN", publish_action.diff
  end

  test "a part's slug must be of the correct format" do
    edition_one = GuideEdition.new(title: "One", slug: "one", panopticon_id: @artefact.id)
    edition_one.parts.build title: "Part One", body:"Never gonna give you up", slug: "part-One-1"
    edition_one.save!

    edition_one.parts[0].slug = "part one"
    assert_raise (Mongoid::Errors::Validations) do
      edition_one.save!
    end
  end

  test "parts can be sorted by the order field using a scope" do
    edition = GuideEdition.new(title: "One", slug: "one", panopticon_id: @artefact.id)
    edition.parts.build title: "Biscuits", body:"Never gonna give you up", slug: "biscuits", order: 2
    edition.parts.build title: "Cookies", body:"NYAN NYAN NYAN NYAN", slug: "cookies", order: 1
    edition.save!
    edition.reload

    assert_equal "Cookies", edition.parts.in_order.first.title
    assert_equal "Biscuits", edition.parts.in_order.last.title
  end

  test "user should not be able to review an edition they requested review for" do
    user = User.create(name: "Mary")

    edition = ProgrammeEdition.new(title: "Childcare", slug: "childcare", panopticon_id: @artefact.id)
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this programme please."})
    assert ! user.request_amendments(edition, {comment: "Well Done, but work harder"})
  end

  test "a new programme edition with multiple parts creates a full diff when published" do
    user = User.create name: "Mazz"

    edition_one = ProgrammeEdition.new(title: "Childcare", slug: "childcare", panopticon_id: @artefact.id)
    edition_one.parts.build title: "Part One", body:"Content for part one", slug: "part-one"
    edition_one.parts.build title: "Part Two", body:"Content for part two", slug: "part-two"
    edition_one.save!

    edition_one.state = :ready
    user.publish edition_one, comment: "First edition"

    edition_two = edition_one.build_clone
    edition_two.save!
    edition_two.parts.first.update_attribute :body, "Some other content"
    edition_two.state = :ready
    user.publish edition_two, comment: "Second edition"

    publish_action = edition_two.actions.where(request_type: "publish").last

    assert_equal "# Part One\n\n{\"Content for part one\" >> \"Some other content\"}\n\n# Part Two\n\nContent for part two", publish_action.diff
  end

  test "a published publication with a draft edition is in progress" do
    dummy_answer = template_published_answer
    assert !dummy_answer.has_sibling_in_progress?

    edition = dummy_answer.build_clone
    edition.save

    dummy_answer.reload
    assert dummy_answer.has_sibling_in_progress?
  end

  test "a draft edition cannot be published" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    edition.start_work
    refute edition.can_publish?
  end

  test "a draft edition can be emergency published" do
    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "draft")
    edition.start_work
    assert edition.can_emergency_publish?
  end


  # test denormalisation

  test "should denormalise an edition with an assigned user and action requesters" do
    @user1 = FactoryGirl.create(:user, name: "Morwenna")
    @user2 = FactoryGirl.create(:user, name: "John")
    @user3 = FactoryGirl.create(:user, name: "Nick")

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "archived")

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "archived", assigned_to_id: @user1.id)
    edition.actions.create request_type: Action::CREATE, requester: @user2
    edition.actions.create request_type: Action::PUBLISH, requester: @user3
    edition.actions.create request_type: Action::ARCHIVE, requester: @user1
    edition.save! and edition.reload

    assert_equal @user1.name, edition.assignee
    assert_equal @user2.name, edition.creator
    assert_equal @user3.name, edition.publisher
    assert_equal @user1.name, edition.archiver
  end

  test "should denormalise an assignee's name when an edition is assigned" do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "lined_up")
    @user1.assign edition, @user2

    assert_equal @user2, edition.assigned_to
    assert_equal @user2.name, edition.assignee
  end

  test "should denormalise a creator's name when an edition is created" do
    @user = FactoryGirl.create(:user)
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

    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, @user, {})

    assert_equal @user.name, edition.creator
  end

  test "should denormalise a publishing user's name when an edition is published" do
    @user = FactoryGirl.create(:user)

    edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    @user.publish edition, { }

    assert_equal @user.name, edition.publisher
  end

  test "should set siblings in progress to nil for new editions" do
    @user = FactoryGirl.create(:user)
    @edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    @published_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    assert_equal 1, @edition.version_number
    assert_nil @edition.sibling_in_progress
  end

  test "should update previous editions when new edition is added" do
    @user = FactoryGirl.create(:user)
    @edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    @published_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    @new_edition = @published_edition.build_clone
    @new_edition.save
    @published_edition.reload

    assert_equal 2, @new_edition.version_number
    assert_equal 2, @published_edition.sibling_in_progress
  end

  test "should update previous editions when new edition is published" do
    @user = FactoryGirl.create(:user)
    @edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "ready")
    @published_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    @new_edition = @published_edition.build_clone
    @new_edition.save
    @new_edition.update_attribute(:state, "ready")
    @user.publish(@new_edition, comment: "Publishing this")
    @published_edition.reload

    assert_equal 2, @new_edition.version_number
    assert_nil @new_edition.sibling_in_progress
    assert_nil @published_edition.sibling_in_progress
  end

  test "all subclasses should provide a working whole_body method for diffing" do
    Edition.subclasses.each do |klass|
      assert klass.instance_methods.include?(:whole_body), "#{klass} doesn't provide a whole_body"
      assert_nothing_raised do
        klass.new.whole_body
      end
    end
  end

  test "should convert a GuideEdition to an AnswerEdition" do
    guide_edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id, state: "published")
    answer_edition = guide_edition.build_clone(AnswerEdition)

    assert_equal guide_edition.whole_body, answer_edition.whole_body
  end

  test "should convert an AnswerEdition to a GuideEdition" do
    answer_edition = template_published_answer
    guide_edition = answer_edition.build_clone(GuideEdition)

    expected = "# Part One\n\n" + answer_edition.whole_body

    assert_equal expected, guide_edition.whole_body
  end

  test "should not allow any changes to an edition with an archived artefact" do
    artefact = FactoryGirl.create(:artefact)
    guide_edition = FactoryGirl.create(:guide_edition, state: 'draft', panopticon_id: artefact.id)
    artefact.state = 'archived'
    artefact.save

    assert_raise(RuntimeError) do
      guide_edition.title = "Error this"
      guide_edition.save!
    end
  end

  test "should return related artefact" do
    assert_equal "Foo bar", template_published_answer.artefact.name
  end

  context "indexable_content" do
    context "editions with a 'body'" do
      should "include the body with markup removed" do
        edition = FactoryGirl.create(:answer_edition, body: "## Title", panopticon_id: FactoryGirl.create(:artefact).id)
        assert_equal "Title", edition.indexable_content
      end
    end

    context "for a single part thing" do
      should "have the normalised content of that part" do
        edition = FactoryGirl.create(:guide_edition, :state => 'ready', :title => 'one part thing', :alternative_title => 'alternative one part thing', panopticon_id: FactoryGirl.create(:artefact).id)
        edition.publish
        assert_equal "alternative one part thing", edition.indexable_content
      end
    end

    context "for a multi part thing" do
      should "have the normalised content of all parts" do
        edition = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'ready', panopticon_id: FactoryGirl.create(:artefact).id)
        edition.publish
        assert_equal "PART ! This is some version text. PART !! This is some more version text.", edition.indexable_content
      end
    end

    context "indexable_content would contain govspeak" do
      should "convert it to plaintext" do
        edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, :state => 'ready', panopticon_id: FactoryGirl.create(:artefact).id)
        edition.publish

        expected = "Some Part Title! This is some version text. Another Part Title This is link text."
        assert_equal expected, edition.indexable_content
      end
    end
  end
end
