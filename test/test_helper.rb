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

  def setup_bare_repo_with_hook
    FileUtils.mkdir_p REMOTE_REPO_DIR
    FileUtils.cd REMOTE_REPO_DIR do
      `git init --bare`
      File.open("hooks/post-receive", "a") do |hook|
        hook.puts "while read old_rev new_rev ref; do"
        hook.puts "  ruby #{PATH_TO_HOOK} $ref $old_rev $new_rev"
        hook.puts "done"
        hook.chmod(0777)
      end
      `git config hooks.campfire.subdomain example`
      `git config hooks.campfire.email login@example.com`
      `git config hooks.campfire.password secret`
      `git config hooks.campfire.ssl true`
      `git config hooks.campfire.room Watercooler`
    end
  end

  def setup_working_repo_with_bare_as_origin
    FileUtils.mkdir_p WORKING_REPO_DIR
    FileUtils.cd WORKING_REPO_DIR do
      `git init`
      `git config user.name 'Arthur Author'`
      `git config user.email 'arthur@example.com'`
      `git remote add origin #{REMOTE_REPO_DIR}`
    end
  end

  def delete_git_repos
    FileUtils.rm_rf TMP_DIR
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
