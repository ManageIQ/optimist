#!/usr/bin/env ruby
require_relative '../lib/optimist'

opts = Optimist::options do
  opt :french, "starts with french", type: String,
      permitted: %w(fries toast),
      permitted_response: "option %{arg} must be something that starts " +
      "with french, e.g. %{permitted} but you gave '%{given}'"
  opt :dog, "starts with dog", permitted: %r/(house|bone|tail)/, type: String
  opt :zipcode, "zipcode", permitted: %r/^[0-9]{5}$/, default: '39759',
      permitted_response: "option %{arg} must be a zipcode, a five-digit number from 00000..99999"
end

p opts

