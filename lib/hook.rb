#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'notification')

if ARGV.length != 3
  puts "Usage:  #{$0} ref oldrev newrev"
  exit
end

refname = ARGV[0]
oldrev  = `git rev-parse #{ARGV[1]}`.strip
newrev  = `git rev-parse #{ARGV[2]}`.strip

GitCampfireNotification.new(refname, oldrev, newrev)
