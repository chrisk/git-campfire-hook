require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fileutils'

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
    lines = output.split("\n")
    lines.select { |line| line =~ /^\[campfire( p)?\] / }.map { |line| line.strip }
  end

  def should_say(what)
    should_output(what)
  end

  def should_paste(what)
    should_output(what, :paste)
  end

  def should_output(what, paste = false)
    should "#{paste ? 'paste' : 'say'} #{what.inspect}" do
      output_marker = paste ? 'campfire p' : 'campfire'
      lines = self.class.filter_output(@output)
      matching_line = lines.detect { |line|
        content = line.sub(/^\[#{output_marker}\] /, '')
        line =~ /^\[#{output_marker}\] / && (what.is_a?(Regexp) ? (content =~ what) : (content == what))
      }
      assert_not_nil matching_line
    end
  end

end

Test::Unit::TestCase.send(:include, GitCampfireHookTestHelper)
Test::Unit::TestCase.extend(GitCampfireHookShouldaMacros)
