#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'notification')
require 'yaml'

if ARGV.length != 3
  puts "Usage:  #{$0} ref oldrev newrev"
  exit
end


config_data = `git config --get-regexp hooks\\.campfire`
campfire_config = config_data.inject({}) do |hash, line|
  line.match(/^hooks\.campfire\.([a-z\-\.]+)\s+(.+)$/)
  hash.merge($1.to_sym => $2)
end
campfire_config[:ssl] = (campfire_config[:ssl] =~ /^yes|true|on|1$/)

GitCampfireNotification.new(:ref_name        => ARGV[0],
                            :old_revision    => `git rev-parse #{ARGV[1]}`.strip,
                            :new_revision    => `git rev-parse #{ARGV[2]}`.strip,
                            :campfire_config => campfire_config)
