#!/usr/bin/env ruby

if ARGV.length != 3
  puts "Usage:  #{$0} ref oldrev newrev"
  exit
end

refname = ARGV[0]
oldrev  = `git rev-parse #{ARGV[1]}`.strip
newrev  = `git rev-parse #{ARGV[2]}`.strip




class GitCampfireNotification

  def initialize(refname, oldrev, newrev)
    @ref_name     = refname
    @old_revision = oldrev
    @new_revision = newrev
    @old_revision_type = `git cat-file -t #{oldrev} 2> /dev/null`.strip
    @new_revision_type = `git cat-file -t #{newrev} 2> /dev/null`.strip

    if ref_name_type.include?("branch")
      send "#{change_type}_branch"
    end
  end


  def project_name
    project_name = `git rev-parse --git-dir 2>/dev/null`.strip
    if project_name == ".git"
      project_name = File.basename(Dir.pwd)
    end
    project_name.sub(/\.git$/, "")
  end

  def change_type
    if @old_revision =~ /^0*$/
      :create
    elsif @new_revision =~ /^0*$/
      :delete
    else
      :update
    end
  end

  def short_ref_name
    @ref_name.match(%r{^refs/(?:tags|heads|remotes)/(.+)$})[1]
  end

  def ref_name_type
    rev_type = (change_type == :delete) ? @old_revision_type : @new_revision_type
    ref_name_types = {%w(tags    commit) => "tag",
                      %w(tags    tag)    => "annotated tag",
                      %w(heads   commit) => "branch",
                      %w(remotes commit) => "tracking branch"}
    @ref_name.match(%r{^refs/(tags|heads|remotes)/.+$})
    ref_name_types[[$1, rev_type]]
  end


  def new_commits
    revision_range = (change_type == :create) ? @new_revision : "#{@old_revision}..#{@new_revision}"

    other_branches = `git for-each-ref --format='%(refname)' refs/heads/ | grep -F -v #{@ref_name}`
    sentinel = "=-=-*-*-" * 10
    raw_commits = `git rev-parse --not #{other_branches} | git rev-list --reverse --pretty=format:'%cn%n%s%n%n%b#{sentinel}' --stdin #{revision_range}`.split(sentinel)
    raw_commits.pop # last is empty because there's an ending sentinel

    raw_commits.inject([]) { |commits, raw_commit|
      lines = raw_commit.strip.split("\n")
      commits << {:revision  => lines[0].sub(/^commit /, ""),
                  :committer => lines[1],
                  :message   => lines[2..-1].join("\n")}
    }
  end

  def speak_new_commits
    new_commits.each do |c|
      puts "#{c[:committer]} just committed #{c[:revision]}"
      puts "[#{project_name}] #{c[:message]}"
      puts
    end
  end


  def update_branch
    if `git rev-list #{@new_revision}..#{@old_revision}`.empty?
      update_type = :fast_foward
    elsif newrev == `git merge-base #{@old_revision} #{@new_revision}`
      update_type = :rewind
      puts "Notice: the #{project_name}/#{short_ref_name} branch was just rewound to a previous commit"
    else
      update_type = :force
      puts "Notice: the #{project_name}/#{short_ref_name} branch was just force-updated"
    end

    unless update_type == :rewind
      speak_new_commits
    end
  end

  def create_branch
    puts "A new branch was just pushed to #{project_name}/#{short_ref_name}:"
    speak_new_commits
  end

end



GitCampfireNotification.new(refname, oldrev, newrev)