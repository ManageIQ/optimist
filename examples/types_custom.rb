#!/usr/bin/env ruby
require_relative '../lib/optimist'

class ZipCode
  REGEXP = %r/^(?<zip>[0-9]{5})(\-(?<plusfour>[0-9]{4}))?$/
  def initialize(zipstring)
    matcher = REGEXP.match(zipstring)
    raise "Invalid zip-code" unless matcher
    @zip = matcher[:zip]
    @plusfour = matcher[:plusfour]
  end
end

#module Optimist
class ZipCodeOption < Optimist::Option
  # register_alias registers with the global parser.
  register_alias :zipcode
  def type_format ; "=<zip>" ; end # optional for use with help-message
  def parse(paramlist, _neg_given)
    paramlist.map do |plist|
      plist.map do |param_string|
        raise Optimist::CommandlineError, "option '#{self.name}' should be formatted as a zipcode" unless param_string=~ ZipCode::REGEXP
        ZipCode.new(param_string)
      end
    end
  end
end

opts = Optimist::options do
  opt :zipcode, "United states postal code", :type => :zipcode 
end

p opts[:zipcode]

