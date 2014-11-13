module GovukContentModels
  module ActionProcessors
    class BaseProcessor
      attr_accessor :actor, :edition, :action_attributes, :event_attributes

      def initialize(actor, edition, action_attributes={}, event_attributes={})
        @actor = actor
        @edition = edition
        @action_attributes = action_attributes
        @event_attributes = event_attributes
      end

      def processed_edition
        if process? && process
          record_action if record_action?
          edition
        end
      end

      protected

      def process?
        true
      end

      def process
        edition.send(action_name)
      end

      def record_action?
        true
      end

      def action_name
        REQUEST_TYPE_TO_PROCESSOR.invert[self.class.name.slice(/.*::(.*)/, 1)]
      end

      def record_action
        new_action = edition.new_action(actor, action_name, action_attributes || {})
        edition.denormalise_users!
        new_action
      end

      def record_action_without_validation
        new_action = edition.new_action_without_validation(actor, action_name, action_attributes || {})
        edition.denormalise_users!
        new_action
      end

      def requester_different?
        if edition.latest_status_action
          edition.latest_status_action.requester_id != actor.id
        else
          true
        end
      end
    end
  end
end
