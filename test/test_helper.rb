ENV["RACK_ENV"] = "test"

require "bundler/setup"

require "active_support/test_case"
require "shoulda/context"
require "minitest/autorun"
require "mocha/mini_test"
require "mongoid"
require "govuk_content_models/require_all"
require "database_cleaner"
require "gds_api/test_helpers/panopticon"
require "webmock/minitest"
require "govuk_content_models/test_helpers/factories"
require 'govuk_content_models/test_helpers/action_processor_helpers'
require "timecop"
require "byebug"

# The models depend on a zone being set, so tests will fail if we don't
Time.zone = "London"

Mongoid.load! File.expand_path("../../config/mongoid.yml", __FILE__)
Mongoid::Tasks::Database.create_indexes
WebMock.disable_net_connect!

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

class ActiveSupport::TestCase
  PROJECT_ROOT = File.expand_path("../..", __FILE__)

  include GdsApi::TestHelpers::Panopticon
  include GovukContentModels::TestHelpers::ActionProcessorHelpers

  def without_metadata_denormalisation(*klasses, &block)
    klasses.each {|klass| klass.any_instance.stubs(:denormalise_metadata).returns(true) }
    result = yield
    klasses.each {|klass| klass.any_instance.unstub(:denormalise_metadata) }
    result
  end

  def clean_db
    DatabaseCleaner.clean
  end
  set_callback :teardown, :before, :clean_db

  def timecop_return
    Timecop.return
  end
  set_callback :teardown, :before, :timecop_return
end
