ENV["RACK_ENV"] = "test"

require "bundler/setup"

%w[ app/models app/validators app/repositories ].each do |path|
  full_path = File.expand_path("../../#{path}", __FILE__)
  $:.unshift full_path unless $:.include?(full_path)
end

require "active_support/test_case"
require "minitest/autorun"
require "fakeweb"
require "mongoid"
require 'database_cleaner'

Mongoid.load! File.expand_path("../../config/mongoid.yml", __FILE__)
FakeWeb.allow_net_connect = false

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

class ActiveSupport::TestCase
  PROJECT_ROOT = File.expand_path("../..", __FILE__)

  def clean_db
    DatabaseCleaner.clean
  end
  set_callback :teardown, :before, :clean_db
end
