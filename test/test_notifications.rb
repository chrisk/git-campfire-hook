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

    context "with one new commit (fast-forward)" do
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

    context "with one modified commit (force-update)" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          File.open("README", 'a') { |file| file.puts 'Best project ever' }
          `git commit --amend -a -m 'Add README with title'`
          @sha = `git rev-list origin/master..master`.strip
          @output = `git push -f origin master 2>&1`
        end
      end

      should_say   "The remote branch testrepo/master was just force-updated"
      should_say   lambda { %r|^Arthur Author just committed #{@sha}$| }
      should_paste "[testrepo] Add README with title"
      should_have_lines_of_output 3
    end

    context "with the previous HEAD removed (rewind)" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          File.open("README", 'a') { |file| file.puts 'Best project ever' }
          `git commit -a -m 'Add title to README'`
          `git push origin master 2>&1`
          `git reset --hard HEAD^`
          @output = `git push -f origin master 2>&1`
        end
      end

      should_say "The remote branch testrepo/master was just rewound to a previous commit"
      should_have_lines_of_output 1
    end
  end


  context "receiving a push that deletes a branch" do
    setup do
      setup_bare_repo_with_hook
      setup_working_repo_with_bare_as_origin
      commit_empty_readme_and_push
      FileUtils.cd WORKING_REPO_DIR do
        @output = `git push origin :master 2>&1`
      end
    end

    teardown { delete_git_repos }

    should_say "The remote branch testrepo/master was just deleted"
    should_have_lines_of_output 1
  end


  context "receiving a push that includes a new annotated tag" do
    setup do
      setup_bare_repo_with_hook
      setup_working_repo_with_bare_as_origin
      commit_empty_readme_and_push
      FileUtils.cd WORKING_REPO_DIR do
        `git tag -a first_release -m "Tag first release" HEAD`
        @sha = `git rev-parse first_release`.strip
        @output = `git push --tags 2>&1`
      end
    end

    teardown { delete_git_repos }

    should_say   lambda { "Arthur Author just pushed a new annotated tag, testrepo/first_release points to #{@sha[0...8]}:" }
    should_paste "[testrepo] Tag first release"
    should_have_lines_of_output 2
  end


  context "receiving a push that includes a new lightweight tag" do
    setup do
      setup_bare_repo_with_hook
      setup_working_repo_with_bare_as_origin
      commit_empty_readme_and_push
      FileUtils.cd WORKING_REPO_DIR do
        `git tag first_release master`
        @sha = `git rev-parse first_release`.strip
        @output = `git push --tags 2>&1`
      end
    end

    teardown { delete_git_repos }

    should_say lambda { "A new lightweight tag was just pushed; testrepo/first_release is #{@sha[0...8]}" }
    should_have_lines_of_output 1
  end

end
