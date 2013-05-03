module Attachable
  class ApiClientNotPresent < StandardError; end

  @asset_api_client = nil

  def self.asset_api_client
    @asset_api_client
  end

  def self.asset_api_client=(api_client)
    @asset_api_client = api_client
  end

  module ClassMethods
    def attaches(*fields)
      fields.map(&:to_s).each do |field|
        before_save "upload_#{field}".to_sym, :if => "#{field}_has_changed?".to_sym
        self.field "#{field}_id".to_sym, type: String

        define_method(field) do
          raise ApiClientNotPresent unless Attachable.asset_api_client.present?
          unless self.send("#{field}_id").blank?
            @attachments ||= { }
            @attachments[field] ||= Attachable.asset_api_client.asset(self.send("#{field}_id"))
          end
        end

        define_method("#{field}=") do |file|
          instance_variable_set("@#{field}_has_changed", true)
          instance_variable_set("@#{field}_file", file)
        end

        define_method("#{field}_has_changed?") do
          instance_variable_get("@#{field}_has_changed")
        end

        define_method("remove_#{field}=") do |value|
          unless value.blank?
            self.send("#{field}_id=", nil)
          end
        end

        define_method("upload_#{field}") do
          raise ApiClientNotPresent unless Attachable.asset_api_client.present?
          begin
            response = Attachable.asset_api_client.create_asset(:file => instance_variable_get("@#{field}_file"))
            self.send("#{field}_id=", response.id.match(/\/([^\/]+)\z/) {|m| m[1] })
          rescue StandardError
            errors.add("#{field}_id".to_sym, "could not be uploaded")
          end
        end
        private "upload_#{field}".to_sym
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
