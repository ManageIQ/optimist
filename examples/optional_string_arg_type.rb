#!/usr/bin/env ruby
require_relative '../lib/optimist_xl'

#module OptimistXL

opts = OptimistXL::options do
  opt :abc, "spec as a string or a flag", :type => :stringflag
  opt :xyz, "spec as a string or a flag", :type => :string
end

p opts
p ARGV

