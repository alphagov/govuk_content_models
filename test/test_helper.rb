ENV["RACK_ENV"] = "test"

require "bundler/setup"

%w[ app/models app/validators app/repositories app/traits lib ].each do |path|
  full_path = File.expand_path("../../#{path}", __FILE__)
  $:.unshift full_path unless $:.include?(full_path)
end

require "active_support/test_case"
require "shoulda/context"
require "minitest/autorun"
require "mongoid"
require "database_cleaner"
require "gds_api/test_helpers/panopticon"
require "webmock/test_unit"
require "govuk_content_models/test_helpers/factories"

Mongoid.load! File.expand_path("../../config/mongoid.yml", __FILE__)
WebMock.disable_net_connect!

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

class ActiveSupport::TestCase
  PROJECT_ROOT = File.expand_path("../..", __FILE__)

  include GdsApi::TestHelpers::Panopticon

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
end
