#!/usr/bin/env ruby
require_relative '../lib/optimist_xl'

opts = OptimistXL::options do
  opt :cone, "Ice cream cone"
  opt :zippy, "It zips"
  opt :zapzy, "It zapz"
  opt :big_bug, "Madagascar cockroach"
end
p opts

