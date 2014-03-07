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
    p.save
    p
  end

  def template_guide
    edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    edition.save
    edition
  end

  def publisher_and_guide
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, panopticon_id: @artefact.id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")
    edition = guide
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

    user.request_review(transaction, {comment: "Review this guide please."})
    transaction.save
    other_user.approve_review(transaction, {comment: "I've reviewed it"})
    transaction.save
    user.publish(transaction, {comment: "Let's go"})
    transaction.save
    return user, transaction
  end

  context "#status_text" do
    should "return a capitalized text representation of the state" do
      assert_equal 'Ready', FactoryGirl.build(:edition, state: 'ready').status_text
    end

    should "also return scheduled publishing time when the state is scheduled for publishing" do
      edition = FactoryGirl.build(:edition, :scheduled_for_publishing)
      expected_status_text = 'Scheduled for publishing on ' + edition.publish_at.strftime("%d/%m/%Y %H:%M")

      assert_equal expected_status_text, edition.status_text
    end
  end

  context "#locked_for_edit?" do
    should "return true if edition is scheduled for publishing for published" do
      assert FactoryGirl.build(:edition, :scheduled_for_publishing).locked_for_edits?
      assert FactoryGirl.build(:edition, :published).locked_for_edits?
    end

    should "return false if in draft state" do
      refute FactoryGirl.build(:edition, state: 'draft').locked_for_edits?
    end
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

  test "a new answer is in draft" do
    g = AnswerEdition.new(slug: "childcare", panopticon_id: @artefact.id, title: "My new answer")
    assert g.draft?
  end

  test "a new guide has draft but isn't published" do
    g = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id)
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

    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    user.send_fact_check(edition,{comment: "Review this guide please.", email_addresses: "test@test.com"})
    user.receive_fact_check(edition, {comment: "Text.<l>content that the SafeHtml validator would catch</l>"})

    assert_equal "Text.<l>content that the SafeHtml validator would catch</l>", edition.actions.last.comment
  end

  test "fact_check_received can go back to out for fact_check" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")
    edition = guide

    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    user.send_fact_check(edition,{comment: "Review this guide please.", email_addresses: "test@test.com"})
    user.receive_fact_check(edition, {comment: "Text.<l>content that the SafeHtml validator would catch</l>"})
    user.send_fact_check(edition,{comment: "Out of office reply triggered receive_fact_check", email_addresses: "test@test.com"})

    assert(edition.actions.last.comment.include? "Out of office reply triggered receive_fact_check\n\nResponses should be sent to:")
  end

  test "when processing fact check, an edition can request for amendments" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")
    edition = guide

    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    user.send_fact_check(edition,{comment: "Review this guide please.", email_addresses: "test@test.com"})
    other_user.request_amendments(edition,{comment: "More amendments are required", email_addresses: "foo@bar.com"})

    assert_equal "More amendments are required", edition.actions.last.comment
  end

  test "ready items may require further amendments" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")
    another_user = User.create(name: "Fiona")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title", alternative_title: "My Other Title")
    edition = guide

    user.request_review(edition,{comment: "Review this guide please."})
    other_user.approve_review(edition, {comment: "I've reviewed it"})
    another_user.request_amendments(edition,{comment: "More amendments are required", email_addresses: "foo@bar.com"})

    assert_equal "More amendments are required", edition.actions.last.comment
  end

  test "check counting reviews" do
    user = User.create(name: "Ben")
    other_user = User.create(name: "James")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

    assert_equal 0, guide.rejected_count

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

    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this guide please."})
    refute user.request_amendments(edition, {comment: "Well Done, but work harder"})
    refute user.can_request_amendments?(edition)
  end

  test "user should not be able to okay a guide they requested review for" do
    user = User.create(name: "Ben")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

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

    assert edition.can_request_review?
    user.request_review(edition,{comment: "Review this guide please."})
    refute edition.can_request_review?
    assert edition.can_request_amendments?
    other_user.request_amendments(edition, {comment: "I've reviewed it"})
    refute edition.can_request_amendments?
    user.request_review(edition,{comment: "Review this guide please."})
    assert edition.can_approve_review?
    other_user.approve_review(edition, {comment: "Looks good to me"})
    assert edition.can_request_amendments?
    assert edition.can_publish?
  end

  test "user should not be able to okay a programme they requested review for" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")

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

  test "User can request amendments for an edition they just approved" do
    user_1, user_2 = template_users
    edition = user_1.create_edition(:answer, panopticon_id: @artefact.id, title: "Answer foo", slug: "answer-foo")
    edition.body = "body content"
    user_1.assign(edition, user_2)
    user_1.request_review(edition,{comment: "Review this guide please."})
    assert edition.in_review?

    user_2.approve_review(edition, {comment: "Looks good just now"})
    assert edition.ready?

    user_2.request_amendments(edition, {comment: "More work needed"})
    assert edition.amends_needed?
  end
end
