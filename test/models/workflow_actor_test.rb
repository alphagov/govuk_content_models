require_relative "../test_helper"
require "user"

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

end
