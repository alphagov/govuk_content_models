lib = File.expand_path("../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "rake"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

require "gem_publisher"
task :publish_gem do |t|
  gem = GemPublisher.publish_if_updated("gds_content_models.gemspec", :gemfury)
  puts "Published #{gem}" if gem
end

task :default => :test
