require File.join(File.dirname(__FILE__), "test_helper")

class TestNotifications < Test::Unit::TestCase

  context "receiving a push that creates a branch" do
    setup    { setup_bare_repo_with_hook
               setup_working_repo_with_bare_as_origin }
    teardown { delete_git_repos }


    context "with one commit" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          FileUtils.touch "README"
          `git add README`
          `git commit -m 'Add empty README'`
          @sha = `git rev-list --all`.strip
          @output = `git push origin master 2>&1`
        end
      end

      should_say   "A new remote branch was just pushed to testrepo/master:"
      should_say   lambda { %r|^Arthur Author just committed #{@sha}$| }
      should_paste "[testrepo] Add empty README"
      should_have_lines_of_output 3
    end


    context "with two commits" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          FileUtils.touch "README"
          `git add README`
          `git commit -m 'Add empty README'`
          File.open("README", 'a') { |file| file.puts 'Best project ever' }
          `git commit -a -m 'Add title to README'`
          @shas = `git rev-list --all`.split
          @output = `git push origin master 2>&1`
        end
      end

      should_say   "A new remote branch was just pushed to testrepo/master:"
      should_say   lambda { %r|^Arthur Author just committed #{@shas[0]}$| }
      should_paste "[testrepo] Add empty README"
      should_say   lambda { %r|^Arthur Author just committed #{@shas[1]}$| }
      should_paste "[testrepo] Add title to README"
      should_have_lines_of_output 5
    end

  end


  context "receiving a push that updates a branch" do
    setup    { setup_bare_repo_with_hook
               setup_working_repo_with_bare_as_origin
               commit_empty_readme_and_push }
    teardown { delete_git_repos }

    context "with one commit" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          File.open("README", 'a') { |file| file.puts 'Best project ever' }
          `git commit -a -m 'Add title to README'`
          @sha = `git rev-list origin/master..master`.strip
          @output = `git push origin master 2>&1`
        end
      end

      should_say   lambda { %r|^Arthur Author just committed #{@sha}$| }
      should_paste "[testrepo] Add title to README"
      should_have_lines_of_output 2
    end
  end

end
