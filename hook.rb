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


puts refname_type
puts short_refname
