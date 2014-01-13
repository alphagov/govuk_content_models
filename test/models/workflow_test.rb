require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  def template_users
    user = User.create(name: "Bob")
    other_user = User.create(name: "James")
    return user, other_user
  end

  def template_programme
    p = ProgrammeEdition.new(slug:"childcare", title:"Children", panopticon_id: @artefact.id)
    p.start_work
    p.save
    p
  end

  def template_guide
    edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    edition.start_work
    edition.save
    edition
  end

  def publisher_and_guide
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, panopticon_id: @artefact.id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")
    edition = guide
    user.start_work(edition)
    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    user.send_fact_check(edition,{comment: "Review this guide please.", email_addresses: "test@test.com"})
    user.receive_fact_check(edition, {comment: "No changes needed, this is all correct"})
    other_user.approve_fact_check(edition, {comment: "Looks good to me"})
    user.publish(edition, {comment: "PUBLISHED!"})
    return user, guide
  end

  def template_user_and_published_transaction
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")
    expectation = Expectation.create text:"Credit card required"

    transaction = user.create_edition(:transaction, title: "My title", slug: "my-title", panopticon_id: @artefact.id)
    transaction.expectation_ids = [expectation.id]
    transaction.save

    transaction.start_work
    transaction.save
    user.request_review(transaction, {comment: "Review this guide please."})
    transaction.save
    other_user.approve_review(transaction, {comment: "I've reviewed it"})
    transaction.save
    user.publish(transaction, {comment: "Let's go"})
    transaction.save
    return user, transaction
  end

  test "permits the creation of new editions" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.published?

    reloaded_transaction = TransactionEdition.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction)

    assert new_edition.save
  end

  test "should allow creation of new editions from GuideEdition to AnswerEdition" do
    user, guide = publisher_and_guide
    new_edition = user.new_version(guide, AnswerEdition)

    assert_equal "AnswerEdition", new_edition._type
  end

  test "a new answer is lined up" do
    g = AnswerEdition.new(slug: "childcare", panopticon_id: @artefact.id, title: "My new answer")
    assert g.lined_up?
  end

  test "starting work on an answer removes it from lined up" do
    g = AnswerEdition.new(slug: "childcare", panopticon_id: @artefact.id, title: "My new answer")
    g.save!
    user = User.create(name: "Ben")
    user.start_work(g)
    assert_equal false, g.lined_up?
  end

  test "a new guide has lined_up but isn't published" do
    g = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id)
    assert g.lined_up?
    refute g.published?
  end

  test "when work started a new guide has draft but isn't published" do
    g = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id)
    g.start_work
    assert g.draft?
    refute g.published?
  end

  test "a guide should be marked as having reviewables if requested for review" do
    guide = template_guide
    user = User.create(name:"Ben")
    refute guide.in_review?
    user.request_review(guide, {comment: "Review this guide please."})
    assert guide.in_review?
  end

  test "guide workflow" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this guide please."})
    refute edition.can_request_review?
    assert edition.can_request_amendments?
    other_user.request_amendments(edition, {comment: "I've reviewed it"})
    refute edition.can_request_amendments?
    user.request_review(edition,{comment: "Review this guide please."})
    assert edition.can_approve_review?
    other_user.approve_review(edition, {comment: "Looks good to me"})
    assert edition.can_publish?
  end

  test "when fact check has been initiated it can be skipped" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    edition = user.create_edition(:guide, panopticon_id: @artefact.id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")

    user.start_work(edition)
    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    user.send_fact_check(edition,{comment: "Review this guide please.", email_addresses: "test@test.com"})

    assert other_user.skip_fact_check(edition, {comment: 'Fact check not received in time'})
    edition.reload
    assert edition.can_publish?
    assert edition.actions.detect { |e| e.request_type == 'skip_fact_check' }
  end

  # until we improve the validation to produce few or no false positives
  test "when processing fact check, it is not validated" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")
    edition = guide
    user.start_work(edition)
    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    user.send_fact_check(edition,{comment: "Review this guide please.", email_addresses: "test@test.com"})
    user.receive_fact_check(edition, {comment: "Text.<l>content that the SafeHtml validator would catch</l>"})

    assert_equal "Text.<l>content that the SafeHtml validator would catch</l>", edition.actions.last.comment
  end

  test "check counting reviews" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

    assert_equal 0, guide.rejected_count

    user.start_work(edition)
    user.request_review(edition,{comment: "Review this guide please."})
    other_user.request_amendments(edition, {comment: "I've reviewed it"})

    assert_equal 1, guide.rejected_count

    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "Looks good to me"})

    assert_equal 1, guide.rejected_count
  end

  test "user should not be able to review a guide they requested review for" do
    user = User.create(name: "Ben")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this guide please."})
    refute user.request_amendments(edition, {comment: "Well Done, but work harder"})
  end

  test "user should not be able to okay a guide they requested review for" do
    user = User.create(name: "Ben")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this guide please."})
    refute user.approve_review(edition, "")
  end

  test "a new programme has drafts but isn't published" do
    p = template_programme
    assert p.draft?
    refute p.published?
  end

  test "a programme should be marked as having reviewables if requested for review" do
    programme = template_programme
    user, other_user = template_users

    refute programme.in_review?
    user.request_review(programme, {comment: "Review this programme please."})
    assert programme.in_review?, "A review was not requested for this programme."
  end

  test "programme workflow" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this guide please."})
    refute edition.can_request_review?
    assert edition.can_request_amendments?
    other_user.request_amendments(edition, {comment: "I've reviewed it"})
    refute edition.can_request_amendments?
    user.request_review(edition,{comment: "Review this guide please."})
    assert edition.can_approve_review?
    other_user.approve_review(edition, {comment: "Looks good to me"})
    assert edition.can_publish?
  end

  test "user should not be able to okay a programme they requested review for" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")
    user.start_work(edition)
    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this programme please."})
    refute user.approve_review(edition, "")
  end

  test "you can only create a new edition from a published edition" do
    user, other_user = template_users
    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")
    refute edition.published?
    refute user.new_version(edition)
  end

  test "a new edition of an answer creates a diff when published" do
    without_metadata_denormalisation(AnswerEdition) do
      edition_one = AnswerEdition.new(title: "Chucking wood", slug: "woodchuck", panopticon_id: @artefact.id)
      edition_one.body = "A woodchuck would chuck all the wood he could chuck if a woodchuck could chuck wood."
      edition_one.state = :ready
      edition_one.save!

      user = User.create name: "Michael"
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.body = "A woodchuck would chuck all the wood he could chuck if a woodchuck could chuck wood.\nAlthough no more than 361 cubic centimetres per day."
      edition_two.state = :ready
      edition_two.save!

      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "A woodchuck would chuck all the wood he could chuck if a woodchuck could chuck wood.{+\"\\nAlthough no more than 361 cubic centimetres per day.\"}", publish_action.diff
    end
  end

  test "handles inconsistent newlines" do
    # Differ tries to be smart when calculating changes, by searching for a matching line
    # later in the texts. When we have predominantly Windows-style new lines (\r\n) with
    # a few Unix-style new lines (\n), a Unix-style new line later in one document will be
    # matched to a Unix-style new line in the other, causing large swathes of spurious diff.

    edition_one = AnswerEdition.new(title: "Chucking wood", slug: "woodchuck", panopticon_id: @artefact.id)
    edition_one.body = "badger\n\nmushroom\r\n\r\nsnake\n\nend"

    edition_two = AnswerEdition.new(title: "Chucking wood", slug: "woodchuck", panopticon_id: @artefact.id)
    edition_two.body = "badger\r\n\r\nmushroom\r\n\r\nsnake\n\nend"
    edition_two.stubs(:published_edition).returns(edition_one)

    # Test that the diff output is simply the (normalised) string, with no diff markers
    assert_equal "badger\n\nmushroom\n\nsnake\n\nend", edition_two.edition_changes.to_s
  end

  test "an edition can be moved into archive state" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")
    user.take_action!(edition, "archive")
    assert_equal "archived", edition.state
  end

  # Mongoid 2.x marks array fields as dirty whenever they are accessed.
  # See https://github.com/mongoid/mongoid/issues/2311
  # This behaviour has been patched in lib/mongoid/monkey_patches.rb
  # in order to prevent workflow validation failures for editions
  # with array fields.
  #
  test "not_editing_published_item should not consider unchanged array fields as changes" do
    bs = FactoryGirl.create(:business_support_edition, state: 'published', sectors: [])
    assert_empty bs.errors
    bs.sectors # Access the Array field
    bs.valid?
    assert_empty bs.errors
    bs.sectors << 'education'
    assert_equal ['sectors'], bs.changes.keys
    bs.valid?
    assert_equal "Published editions can't be edited", bs.errors[:base].first
  end
end
