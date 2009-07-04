require 'rubygems'
require 'test/unit'
require 'shoulda'

ENV["USE_STDOUT"] = "1"

module GitCampfireHookTestHelper

  unless defined?(TMP_DIR)
    TMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'tmp'))
    WORKING_REPO_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'tmp', 'working'))
    REMOTE_REPO_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'tmp', 'testrepo'))
    PATH_TO_HOOK = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'hook.rb'))
  end

  def capture_stdout
    $stdout = StringIO.new
    yield
    $stdout.rewind && $stdout.read
  ensure
    $stdout = STDOUT
  end

end

Test::Unit::TestCase.send(:include, GitCampfireHookTestHelper)
