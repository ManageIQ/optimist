# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'trollop/VERSION'
require 'trollop'

Gem::Specification.new do |spec|
  spec.name          = "trollop"
  spec.version       = Trollop::VERSION
  spec.authors       = ["William Morgan", "Keenan Brock"]
  spec.email         = "keenan@thebrocks.net"
  spec.summary       = "Trollop is a commandline option parser for Ruby that just gets out of your way."
  spec.description   = "Trollop is a commandline option parser for Ruby that just
gets out of your way. One line of code per option is all you need to write.
For that, you get a nice automatically-generated help page, robust option
parsing, command subcompletion, and sensible defaults for everything you don't
specify."
  spec.license       = "MIT"
  spec.homepage      = "http://manageiq.github.io/trollop/"
  spec.files         = %w(lib/trollop.rb) + Dir["*.txt"]
  spec.executables   = []
  spec.test_files    = ["test/test_trollop.rb"]

  spec.add_runtime_dependency 'curses'
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 4.7.3"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
end
