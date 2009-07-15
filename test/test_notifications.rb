require File.join(File.dirname(__FILE__), "test_helper")

class TestNotifications < Test::Unit::TestCase

  context "receiving a push" do
    setup    { setup_bare_repo_with_hook
               setup_working_repo_with_bare_as_origin }
    teardown { delete_git_repos }


    context "with one commit" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          FileUtils.touch "README"
          `git add README`
          `git commit -m 'Add empty README'`
          @shas = `git rev-list --all`.split
          @output = `git push origin master 2>&1`
        end
      end

      should_say   "A new remote branch was just pushed to testrepo/master:"
      should_say   lambda { %r|^Arthur Author just committed #{@shas[0]}$| }
      should_paste "[testrepo] Add empty README"
    end


    context "with two commits" do
      setup do
        FileUtils.cd WORKING_REPO_DIR do
          FileUtils.touch "README"
          `git add README`
          `git commit -m 'Add empty README'`
          File.open("README", 'a') do |file|
            file.puts 'Best project ever'
          end
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
    end

  end

end
