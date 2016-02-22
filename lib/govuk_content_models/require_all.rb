# Require this file in a non-Rails app to load all the things
require "active_model"
require "mongoid"
require "govuk_content_models"

root_path = "#{File.dirname(__FILE__)}/../.."
%w[ app/models app/validators app/traits lib ].each do |path|
  full_path = File.expand_path("#{root_path}/#{path}")
  $LOAD_PATH.unshift full_path unless $LOAD_PATH.include?(full_path)
end

# Require validators first, then other files in app
Dir.glob("#{root_path}/app/validators/*.rb").each { |f| require f }
Dir.glob("#{root_path}/app/traits/*.rb").each { |f| require f }
Dir.glob("#{root_path}/app/**/*.rb").each { |f| require f }
