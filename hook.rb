#!/usr/bin/env ruby

if ARGV.length != 3
  puts "Usage:  #{$0} ref oldrev newrev"
  exit
end


refname = ARGV[0]
oldrev  = `git rev-parse #{ARGV[1]}`
newrev  = `git rev-parse #{ARGV[2]}`

change_type =
  if oldrev =~ /^0*$/
    :create
  elsif newrev =~ /^0*$/
    :delete
  else
    :update
  end

newrev_type = `git cat-file -t #{newrev} 2> /dev/null`
oldrev_type = `git cat-file -t #{oldrev} 2> /dev/null`

case change_type
when :create, :update
  rev, rev_type = newrev, newrev_type
when :delete
  rev, rev_type = oldrev, oldrev_type
end