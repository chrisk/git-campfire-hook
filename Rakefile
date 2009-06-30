require 'rubygems'
require 'rake/testtask'

desc "Run All Tests"
Rake::TestTask.new :test do |test|
  test.test_files = ["test/**/*.rb"]
  test.verbose = false
end

task :default => :test
