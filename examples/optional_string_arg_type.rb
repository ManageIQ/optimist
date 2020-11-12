#!/usr/bin/env ruby
require_relative '../lib/optimist_xl'

#module OptimistXL

opts = OptimistXL::options do
  opt :log, "specify optional log-file path", :type => :stringflag, :default => "progname.log"
end
p opts

