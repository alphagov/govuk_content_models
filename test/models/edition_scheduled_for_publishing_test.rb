require "test_helper"

class EditionScheduledForPublishingTest < ActiveSupport::TestCase
  context "#schedule_for_publishing" do
    context "when publish_at is not specified" do
      setup do
        @edition = FactoryGirl.create(:edition, state: 'ready')
        @edition.schedule_for_publishing
        @edition.reload
      end

      should "return an error" do
        assert_includes @edition.errors[:publish_at], "can't be blank"
      end

      should "not complete the transition to scheduled_for_publishing" do
        assert_equal 'ready', @edition.state
      end
    end

    context "when publish_at is specified" do
      setup do
        @edition = FactoryGirl.create(:edition, state: 'ready')
        @publish_when = 1.day.from_now
        @edition.schedule_for_publishing(@publish_when)
        @edition.reload
      end

      should "save publish_at against the edition" do
        assert_equal @publish_when.to_i, @edition.publish_at.to_i
      end

      should "complete the transition to scheduled_for_publishing" do
        assert_equal 'scheduled_for_publishing', @edition.state
      end
    end
  end

  context "when scheduled_for_publishing" do
    should "not allow editing fields like title" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

      edition.title = 'a new title'

      refute edition.valid?
      assert_includes edition.errors.full_messages, "Editions scheduled for publishing can't be edited"
    end

    should "allow editing fields like section" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

      edition.section = 'new section'

      assert edition.save
      assert_equal edition.reload.section, 'new section'
    end

    should "return false for #can_destroy?" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
      refute edition.can_destroy?
    end

    should "allow transition to published state" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
      assert edition.can_publish?
    end
  end

  context "#cancel_scheduled_publishing" do
    setup do
      @edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
      @edition.cancel_scheduled_publishing
      @edition.reload
    end

    should "remove the publish_at stored against the edition" do
      assert_nil @edition.publish_at
    end

    should "complete the transition back to ready" do
      assert_equal 'ready', @edition.state
    end
  end
end
