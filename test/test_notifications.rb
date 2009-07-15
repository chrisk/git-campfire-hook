require File.join(File.dirname(__FILE__), "test_helper")

class TestNotifications < Test::Unit::TestCase

  context "receiving a push with one commit" do
    setup do
      setup_bare_repo_with_hook
      setup_working_repo_with_bare_as_origin
      FileUtils.cd WORKING_REPO_DIR do
        FileUtils.touch "README"
        `git add README`
        `git commit -m 'Add empty README'`
        @output = `git push origin master 2>&1`  # git-push outputs to stderr for some reason
      end
    end

    teardown { delete_git_repos }

    should_say   "A new remote branch was just pushed to testrepo/master:"
    should_say   /^Arthur Author just committed [0-9a-f]{40}$/
    should_paste "[testrepo] Add empty README"
  end

end
