#!/usr/bin/env ruby
require_relative '../lib/optimist'

#module Optimist

opts = Optimist::options do
  opt :log, "specify optional log-file path", :type => :stringflag, :default => "progname.log"
end
p opts

