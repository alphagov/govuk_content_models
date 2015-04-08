module GovukContentModels
  module ActionProcessors
    class ScheduleForPublishingProcessor < BaseProcessor

      def process
        publish_at = action_attributes.delete(:publish_at)
        action_attributes.merge!(request_details: { scheduled_time: publish_at.utc })

        edition.schedule_for_publishing(publish_at)
      end

    end
  end
end
