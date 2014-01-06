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
desc "Publish gem to Gemfury"
task :publish_gem do |t|
  gem = GemPublisher.publish_if_updated("govuk_content_models.gemspec", :rubygems)
  puts "Published #{gem}" if gem
end

task :check_for_bad_time_handling do
  directories = Dir.glob(File.join(File.dirname(__FILE__), '**', '*.rb'))
  matching_files = directories.select do |filename|
    match = false
    File.open(filename, :encoding => 'utf-8') do |file|
      match = file.grep(%r{Time\.(now|utc|parse)}).any?
    end
    match
  end
  if matching_files.any?
    raise <<-MSG

Avoid issues with daylight-savings time by always building instances of
TimeWithZone and not Time. Use methods like:
    Time.zone.now, Time.zone.parse, n.days.ago, m.hours.from_now, etc

in preference to methods like:
    Time.now, Time.utc, Time.parse, etc

Files that contain bad Time handling:
  #{matching_files.join("\n  ")}

MSG
  end
end

task :default => [:test, :check_for_bad_time_handling]
