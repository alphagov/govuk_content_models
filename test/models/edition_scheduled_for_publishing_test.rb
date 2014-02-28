require "test_helper"

class EditionScheduledForPublishingTest < ActiveSupport::TestCase
  context "#schedule_for_publishing" do
    context "when publish_at is not specified" do
      setup do
        @edition = FactoryGirl.create(:edition, state: 'ready')
        @edition.schedule_for_publishing
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
      end

      should "save publish_at against the edition" do
        assert_equal @publish_when.to_i, @edition.publish_at.to_i
      end

      should "complete the transition to scheduled_for_publishing" do
        assert_equal 'scheduled_for_publishing', @edition.state
      end
    end
  end

  context "#cancel_scheduled_publishing" do
    setup do
      @edition = FactoryGirl.create(:edition, state: 'scheduled_for_publishing', publish_at: 1.day.from_now)
      @edition.cancel_scheduled_publishing
    end

    should "remove the publish_at stored against the edition" do
      assert_nil @edition.publish_at
    end

    should "complete the transition back to ready" do
      assert_equal 'ready', @edition.state
    end
  end
end
