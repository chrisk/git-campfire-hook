#!/usr/bin/env ruby

if ARGV.length != 3
  puts "Usage:  #{$0} ref oldrev newrev"
  exit
end


refname = ARGV[0]
oldrev  = `git rev-parse #{ARGV[1]}`.strip
newrev  = `git rev-parse #{ARGV[2]}`.strip

change_type =
  if oldrev =~ /^0*$/
    :create
  elsif newrev =~ /^0*$/
    :delete
  else
    :update
  end

newrev_type = `git cat-file -t #{newrev} 2> /dev/null`.strip
oldrev_type = `git cat-file -t #{oldrev} 2> /dev/null`.strip

case change_type
when :create, :update
  rev, rev_type = newrev, newrev_type
when :delete
  rev, rev_type = oldrev, oldrev_type
end


if refname =~ %r{^refs/(tags|heads|remotes)/(.+)$}
  short_refname = $2

  refname_types = {%w(tags    commit) => "tag",
                   %w(tags    tag)    => "annotated tag",
                   %w(heads   commit) => "branch",
                   %w(remotes commit) => "tracking branch"}
  refname_type = refname_types[[$1, rev_type]]
end



def new_commits(change_type, refname, oldrev, newrev)
  revision_range = (change_type == :create) ? newrev : "#{oldrev}..#{newrev}"

  other_branches = `git for-each-ref --format='%(refname)' refs/heads/ | grep -F -v #{refname}`
  sentinel = "=-=-*-*-" * 10
  puts `git rev-parse --not #{other_branches} | git rev-list --reverse --pretty=format:'%cn%n%s%n%n%b#{sentinel}' --stdin #{revision_range}`
  raw_commits = `git rev-parse --not #{other_branches} | git rev-list --reverse --pretty=format:'%cn%n%s%n%n%b#{sentinel}' --stdin #{revision_range}`.split(sentinel)
  raw_commits.pop # last is empty because there's an ending sentinel

  raw_commits.inject([]) { |commits, raw_commit|
    lines = raw_commit.strip.split("\n")
    commits << {:revision  => lines[0].sub(/^commit /, ""),
                :committer => lines[1],
                :message   => lines[2..-1].join("\n")}
  }
end


def speak_new_commits(commits)
  commits.each do |c|
    # TODO: replace puts with tinder
    puts "#{c[:committer]} just committed #{c[:revision]}"
    puts c[:message]
    puts
  end
end

speak_new_commits(new_commits(change_type, refname, oldrev, newrev))