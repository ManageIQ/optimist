#!/usr/bin/env ruby
require_relative '../lib/optimist'

opts = Optimist::options do
  opt :cone, "Ice cream cone"
  opt :zippy, "It zips"
  opt :zapzy, "It zapz"
  opt :big_bug, "Madagascar cockroach"
end
p opts

