# Require this file in a non-Rails app to load all the things
require "active_model"
require "mongoid"
require "govuk_content_models"

%w[ app/models app/validators app/repositories app/traits lib ].each do |path|
  full_path = File.expand_path(
    "#{File.dirname(__FILE__)}/../../#{path}", __FILE__)
  $LOAD_PATH.unshift full_path unless $LOAD_PATH.include?(full_path)
end

# Require everything under app
Dir.glob("#{File.dirname(__FILE__)}/../../app/**/*.rb").each do |file|
  require file
end
