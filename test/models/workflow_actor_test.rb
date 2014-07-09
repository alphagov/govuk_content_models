require_relative "../test_helper"

class WorkflowActorTest < ActiveSupport::TestCase

  context "creating a new version of an edition" do
    setup do
      @user = User.new
      @user.stubs(:record_action)
      @edition = stub("AnswerEdition", :published? => true, :build_clone => :new_version)
    end

    should "return false if the edition is not published" do
      @edition.stubs(:published?).returns(false)
      @edition.expects(:build_clone).never
      @user.expects(:record_action).never
      assert_equal false, @user.new_version(@edition)
    end

    should "build a clone" do
      @edition.expects(:build_clone).with(nil).returns(:new_verison)
      @user.new_version(@edition)
    end

    should "record the action" do
      @user.expects(:record_action).with(:new_version, Action::NEW_VERSION)
      @user.new_version(@edition)
    end

    should "return the new edition" do
      assert_equal :new_version, @user.new_version(@edition)
    end

    context "creating an edition of a different type" do
      should "build a clone of a new type" do
        @edition.expects(:build_clone).with(GuideEdition).returns(:new_verison)
        @user.new_version(@edition, "GuideEdition")
      end

      should "record the action" do
        @user.expects(:record_action).with(:new_version, Action::NEW_VERSION)
        @user.new_version(@edition)
      end
    end

    context "when building the edition fails" do
      setup do
        @edition.stubs(:build_clone).returns(nil)
      end

      should "not record the action" do
        @user.expects(:record_action).never
        @user.new_version(@edition)
      end

      should "return false" do
        assert_equal false, @user.new_version(@edition)
      end
    end
  end

  context "#receive_fact_check" do
    should "transition an edition with link validation errors to fact_check_received state" do
      edition = FactoryGirl.create(:guide_edition_with_two_parts, state: :fact_check)
      # Internal links must start with a forward slash eg [link text](/link-destination)
      edition.parts.first.update_attribute(:body, "[register and tax your vehicle](registering-an-imported-vehicle)")

      assert edition.invalid?
      assert User.new.receive_fact_check(edition, {})
      assert_equal "fact_check_received", edition.reload.state
    end
  end

  context "#schedule_for_publishing" do
    setup do
      @user = FactoryGirl.build(:user)
      @publish_at = 1.day.from_now
      @activity_details = { publish_at: @publish_at, comment: "Go schedule !" }
    end

    should "return false when scheduling an already published edition" do
      edition = FactoryGirl.create(:edition, state: 'published')
      refute @user.schedule_for_publishing(edition, @activity_details)
    end

    should "schedule an edition for publishing if it is ready" do
      edition = FactoryGirl.create(:edition, state: 'ready')

      edition = @user.schedule_for_publishing(edition, @activity_details)

      assert edition.scheduled_for_publishing?
      assert_equal @publish_at.to_i, edition.publish_at.to_i
    end

    should "record the action" do
      edition = FactoryGirl.create(:edition, state: 'ready')
      @user.expects(:record_action).with(edition, :schedule_for_publishing, { comment: "Go schedule !" })

      @user.schedule_for_publishing(edition, @activity_details)
    end
  end
end
