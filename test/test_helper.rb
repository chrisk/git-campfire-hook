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


module GitCampfireHookShouldaMacros

  def filter_output(output)
    output.select { |line| line =~ /^\[campfire( p)?\] / }.map { |line| line.strip }
  end

  def should_say(what)
    should "say #{what.inspect}" do
      output = self.class.filter_output(@output)
      matching_line = output.select { |line|
        filtered_line = line.sub(/^\[campfire\] /, '')
        line =~ /^\[campfire\] / && (what.is_a?(Regexp) ? (line =~ what) : (line == what.to_s))
      }
      assert_not_nil matching_line
    end
  end

  def should_paste(what)
    should "paste #{what.inspect}" do
      output = self.class.filter_output(@output)
      matching_line = output.select { |line|
        filtered_line = line.sub(/^\[campfire p\] /, '')
        line =~ /^\[campfire p\] / && (what.is_a?(Regexp) ? (line =~ what) : (line == what.to_s))
      }
      assert_not_nil matching_line
    end
  end

end

Test::Unit::TestCase.send(:include, GitCampfireHookTestHelper)
Test::Unit::TestCase.extend(GitCampfireHookShouldaMacros)
