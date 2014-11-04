$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

unless ENV['MUTANT']
  require "coveralls"
  require "simplecov"

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    Coveralls::SimpleCov::Formatter,
    SimpleCov::Formatter::HTMLFormatter,
  ]

end

begin
  require "pry"
rescue LoadError
end

require 'test/unit'

SimpleCov.start unless ENV['MUTANT']

require 'trollop'
