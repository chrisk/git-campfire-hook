require File.join(File.dirname(__FILE__), "test_helper")

class TestNotifications < Test::Unit::TestCase

  context "pushing one commit to a bare repo" do
    setup do
      FileUtils.mkdir_p REMOTE_REPO_DIR
      FileUtils.mkdir_p WORKING_REPO_DIR
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
      FileUtils.cd WORKING_REPO_DIR do
        `git init`
        `git config user.name 'Arthur Author'`
        `git config user.email 'arthur@example.com'`
        `git remote add origin #{REMOTE_REPO_DIR}`
        FileUtils.touch "README"
        `git add README`
        `git commit -m 'Add empty README'`
        @output = `git push origin master 2>&1`  # git-push outputs to stderr for some reason
      end
    end

    teardown do
      FileUtils.rm_rf TMP_DIR
    end

    should_say   "A new remote branch was just pushed to testrepo/master:"
    should_say   /^Arthur Author just committed [0-9a-f]{40}$/
    should_paste "[testrepo] Add empty README"
  end

end
