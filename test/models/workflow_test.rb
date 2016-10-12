require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  def template_users
    user = FactoryGirl.create(:user, name: "Bob")
    other_user = FactoryGirl.create(:user, name: "James")
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
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    guide = user.create_edition(:guide, panopticon_id: @artefact.id, overview: "My Overview", title: "My Title", slug: "my-title")
    edition = guide

    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)
    receive_fact_check(user, edition)
    other_user.progress(edition, { request_type: :approve_fact_check, comment: "Looks good to me" })
    user.progress(edition, { request_type: :publish, comment: "PUBLISHED!" })
    return user, guide
  end

  def template_user_and_published_transaction
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    transaction = user.create_edition(:transaction, title: "My title", slug: "my-title", panopticon_id: @artefact.id, need_to_know: "Credit card required")
    transaction.save

    request_review(user, transaction)
    transaction.save
    approve_review(other_user, transaction)
    transaction.save
    user.progress(transaction, { request_type: :publish, comment: "Let's go"})
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
    user = FactoryGirl.create(:user, name: "Ben")
    refute guide.in_review?
    assert_nil guide.review_requested_at

    now = Time.zone.now
    Timecop.freeze(now) do
      request_review(user, guide)
    end
    assert guide.in_review?
    assert_equal now.to_i, guide.review_requested_at.to_i
  end

  test "a guide not in review cannot have a reviewer" do
    guide = template_guide
    refute guide.in_review?
    guide.reviewer = "Bob"
    refute guide.valid?
    assert guide.errors.has_key?(:reviewer)
  end

  test "guide workflow" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

    assert edition.can_request_review?
    request_review(user, edition)
    refute edition.can_request_review?
    assert edition.can_request_amendments?
    request_amendments(other_user, edition)
    refute edition.can_request_amendments?
    request_review(user, edition)
    assert edition.can_approve_review?
    approve_review(other_user, edition)
    assert edition.can_publish?
  end

  test "skip review workflow" do
    user = FactoryGirl.create(:user, name: "Ben", permissions: ["skip_review"])
    other = FactoryGirl.create(:user, name: "Ben", permissions: ["signin"])

    edition = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)

    assert edition.can_request_review?
    request_review(user, edition)
    assert edition.can_skip_review?
    refute skip_review(other, edition)
    assert skip_review(user, edition)
    assert edition.ready?
    assert edition.can_publish?
  end

  test "when fact check has been initiated it can be skipped" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    edition = user.create_edition(:guide, panopticon_id: @artefact.id, overview: "My Overview", title: "My Title", slug: "my-title")

    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)

    assert other_user.progress(edition, { request_type: :skip_fact_check, comment: 'Fact check not received in time' })
    edition.reload
    assert edition.can_publish?
    assert edition.actions.detect { |e| e.request_type == 'skip_fact_check' }
  end

  # until we improve the validation to produce few or no false positives
  test "when processing fact check, it is not validated" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
    edition = guide

    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)
    receive_fact_check(user, edition, "Text.<l>content that the SafeHtml validator would catch</l>")

    assert_equal "Text.<l>content that the SafeHtml validator would catch</l>", edition.actions.last.comment
  end

  test "fact_check_received can go back to out for fact_check" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
    edition = guide

    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)
    receive_fact_check(user, edition, "Text.<l>content that the SafeHtml validator would catch</l>")
    send_fact_check(user, edition, "Out of office reply triggered receive_fact_check")

    assert(edition.actions.last.comment.include? "Out of office reply triggered receive_fact_check")
  end

  test "when processing fact check, an edition can request for amendments" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
    edition = guide

    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)
    request_amendments(other_user, edition)

    assert_equal 'request_amendments', edition.actions.last.request_type
    assert_equal "More amendments are required", edition.actions.last.comment
  end

  test "ready items may require further amendments" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")
    FactoryGirl.create(:user, name: "Fiona")

    guide = user.create_edition(:guide, panopticon_id: FactoryGirl.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
    edition = guide

    request_review(user, edition)

    edition.reviewer = other_user
    edition.save!

    approve_review(other_user, edition)
    assert_nil edition.reviewer

    request_amendments(other_user, edition)
    assert_equal "More amendments are required", edition.actions.last.comment
  end

  test "check counting reviews" do
    user = FactoryGirl.create(:user, name: "Ben")
    other_user = FactoryGirl.create(:user, name: "James")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

    assert_equal 0, guide.rejected_count

    request_review(user, edition)
    request_amendments(other_user, edition)

    assert_equal 1, guide.rejected_count

    request_review(user, edition)
    approve_review(other_user, edition)

    assert_equal 1, guide.rejected_count
  end

  test "user should not be able to review a guide they requested review for" do
    user = FactoryGirl.create(:user, name: "Ben")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

    assert edition.can_request_review?
    request_review(user, edition)
    refute request_amendments(user, edition)
  end

  test "user should not be able to okay a guide they requested review for" do
    user = FactoryGirl.create(:user, name: "Ben")

    guide = user.create_edition(:guide, title: "My Title", slug: "my-title", panopticon_id: @artefact.id)
    edition = guide

    assert edition.can_request_review?
    request_review(user, edition)
    refute approve_review(user, edition)
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
    request_review(user, programme)
    assert programme.in_review?, "A review was not requested for this programme."
  end

  test "programme workflow" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")

    assert edition.can_request_review?
    request_review(user, edition)
    refute edition.can_request_review?
    assert edition.can_request_amendments?
    request_amendments(other_user, edition)
    refute edition.can_request_amendments?
    request_review(user, edition)
    assert edition.can_approve_review?
    approve_review(other_user, edition)
    assert edition.can_request_amendments?
    assert edition.can_publish?
  end

  test "user should not be able to okay a programme they requested review for" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")

    assert edition.can_request_review?
    request_review(user, edition)
    refute approve_review(user, edition)
  end

  test "you can only create a new edition from a published edition" do
    user, other_user = template_users
    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")
    refute edition.published?
    refute user.new_version(edition)
  end

  test "an edition can be moved into archive state" do
    user, other_user = template_users

    edition = user.create_edition(:programme, panopticon_id: @artefact.id, title: "My title", slug: "my-slug")
    user.progress(edition, { request_type: :archive })
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
    request_review(user_1, edition)
    assert edition.in_review?

    approve_review(user_2, edition)
    assert edition.ready?

    request_amendments(user_2, edition)
    assert edition.amends_needed?
  end

  test "important_note returns last non-resolved important note" do
    user = FactoryGirl.create(:user, name: "Ben")
    edition = template_guide
    user.record_note(edition, 'this is an important note', Action::IMPORTANT_NOTE)
    request_review(user, edition)
    assert_equal edition.important_note.comment, 'this is an important note'

    user.record_note(edition, nil, Action::IMPORTANT_NOTE_RESOLVED)
    assert_nil edition.important_note
  end

  context "creating a new version of an edition" do
    setup do
      @user = User.new
      @edition = FactoryGirl.create(:edition, state: :published)
    end

    should "return false if the edition is not published" do
      @edition.update_attribute(:state, :in_review)
      assert_nil @user.new_version(@edition)
    end

    should "record the action" do
      new_version = @user.new_version(@edition)
      assert_equal 'new_version', new_version.actions.last.request_type
    end

    should "return the new edition" do
      new_version = @user.new_version(@edition)
      assert_includes new_version.previous_siblings.to_a, @edition
    end

    context "creating an edition of a different type" do
      should "build a clone of a new type" do
        assert_equal GuideEdition, @user.new_version(@edition, "GuideEdition").class
      end

      should "record the action" do
        new_version = @user.new_version(@edition)
        assert_equal 'new_version', new_version.actions.last.request_type
      end
    end

    context "when building the edition fails" do
      setup do
        @edition.stubs(:build_clone).returns(nil)
      end

      should "not record the action" do
        assert_no_difference '@edition.actions.count' do
          @user.new_version(@edition)
        end
      end

      should "return nil" do
        assert_nil @user.new_version(@edition)
      end
    end
  end

  context "#receive_fact_check" do
    setup do
      @edition = FactoryGirl.create(:guide_edition_with_two_parts, state: :fact_check)
      # Internal links must start with a forward slash eg [link text](/link-destination)
      @edition.parts.first.update_attribute(:body,
        "[register and tax your vehicle](registering-an-imported-vehicle)")
    end

    should "transition an edition with link validation errors to fact_check_received state" do
      assert @edition.invalid?
      receive_fact_check(User.new, @edition)
      assert_equal "fact_check_received", @edition.reload.state
    end

    should "record the action" do
      assert_difference '@edition.actions.count', 1 do
        receive_fact_check(User.new, @edition)
      end
      assert_equal "receive_fact_check", @edition.actions.last.request_type
    end
  end

  context "#schedule_for_publishing" do
    setup do
      @user = FactoryGirl.build(:user)
      @publish_at = 1.day.from_now.utc
      @activity_details = { publish_at: @publish_at, comment: "Go schedule !" }
    end

    should "return false when scheduling an already published edition" do
      edition = FactoryGirl.create(:edition, state: 'published')
      refute schedule_for_publishing(@user, edition, @activity_details)
    end

    should "schedule an edition for publishing if it is ready" do
      edition = FactoryGirl.create(:edition, state: 'ready')

      schedule_for_publishing(@user, edition, @activity_details)

      assert edition.scheduled_for_publishing?
      assert_equal @publish_at.to_i, edition.publish_at.to_i
    end

    should "record the action" do
      edition = FactoryGirl.create(:edition, state: 'ready')
      options = { comment: "Go schedule !", request_details: { scheduled_time: @publish_at } }

      assert_difference 'edition.actions.count', 1 do
        schedule_for_publishing(@user, edition, @activity_details)
      end
      assert_equal 'schedule_for_publishing', edition.actions.last.request_type
    end
  end
end
