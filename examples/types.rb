#!/usr/bin/env ruby
require_relative '../lib/optimist'

opts = Optimist::options do
  opt :xx, "x opt", :type => :string 
  opt :yy, "y opt", :type => :float
  opt :zz, "z opt", :type => :integer
end
p opts
puts "xx class is #{opts[:xx].class}"
puts "yy class is #{opts[:yy].class}"
puts "zz class is #{opts[:zz].class}"
