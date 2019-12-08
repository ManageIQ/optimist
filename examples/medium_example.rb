#!/usr/bin/env ruby
require_relative '../lib/optimist_xl'

opts = OptimistXL::options do
  version "cool-script v0.1 (code-name: bananas foster)"
  banner "This script is pretty cool."
  opt :juice, "use juice"
  opt :milk, "use milk"
  opt :litres, "quantity of liquid", :default => 2.0
  opt :brand, "brand name of the liquid", :type => :string
  opt :config, "config file path", :type => String, :required => true
  opt :drinkers, "number of people drinking the liquid", :default => 6
end
OptimistXL::die :drinkers, "must be value a greater than zero" if opts[:drinkers] < 1
OptimistXL::die :config, "must point to an existing file" unless File.exist?(opts[:config]) if opts[:config]
