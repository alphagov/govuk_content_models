module Attachable
  module ClassMethods
    def attaches(asset_api_client, *fields)
      fields.map(&:to_s).each do |field|
        before_save "upload_#{field}".to_sym, :if => "#{field}_has_changed?".to_sym
        self.field "#{field}_id".to_sym, type: String

        define_method(field) do
          unless self.send("#{field}_id").blank?
            @attachments ||= { }
            @attachments[field] ||= asset_api_client.asset(self.send("#{field}_id"))
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
          begin
            response = asset_api_client.create_asset(:file => instance_variable_get("@#{field}_file"))
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
    klass.extend  ClassMethods
  end
end
