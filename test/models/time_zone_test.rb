require 'test_helper'

class TimeZoneTest < ActiveSupport::TestCase
  context "use_activesupport_time_zone is set to true, Time.zone is set to 'London'" do
    setup do
      # This context has already been set in the local mongoid.yml, and in test_helper.rb
    end

    should "still store the date in UTC" do
      FactoryGirl.create(:artefact)
      assert_equal 'UTC', Artefact.last[:created_at].zone
      assert_equal 'GMT', Artefact.last.created_at.zone
    end

    should "use the Time.zone time zone for dot-methods" do
      FactoryGirl.create(:artefact)
      assert_equal 'GMT', Artefact.last.created_at.zone
    end

    context "it is currently British Summer Time" do
      should "still store the date in UTC" do
        first_day_of_summer_time = Time.zone.parse("2013-04-01")
        Timecop.freeze(first_day_of_summer_time) do
          FactoryGirl.create(:artefact)
          assert_equal 'UTC', Artefact.last[:created_at].zone
        end
      end

      should "use the time zone with offset for dot-methods" do
        first_day_of_summer_time = Time.zone.parse("2013-04-01")
        Timecop.freeze(first_day_of_summer_time) do
          FactoryGirl.create(:artefact)
          assert_equal 'BST', Artefact.last.created_at.zone
        end
      end
    end
  end
end
