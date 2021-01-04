# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'optimist'

Gem::Specification.new do |spec|
  spec.name          = "optimist"
  spec.version       = Optimist::VERSION
  spec.authors       = ["William Morgan", "Keenan Brock", "Jason Frey", "Ben Bowers"]
  spec.email         = [nil, "keenan@thebrocks.net", "fryguy9@gmail.com", "nanobowers@gmail.com"]
  spec.summary       = "Optimist is feature filled but lightweight commandline option parser."
  spec.description   = "Optimist is feature filled but lightweight commandline option parser.
It contains all of the features of the Optimist gem, plus lots of additional features you didnt know you needed.
One line of code per option is all you typically need to write.
For that, you get a nice automatically-generated help page, robust option
parsing, command subcompletion, and sensible defaults for everything you don't
specify."
  spec.homepage      = "http://manageiq.github.io/optimist"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.metadata    = {
    "changelog_uri"   => "https://github.com/ManageIQ/optimist/blob/master/History.md",
    "source_code_uri" => "https://github.com/ManageIQ/optimist/",
    "bug_tracker_uri" => "https://github.com/ManageIQ/optimist/issues",
  }

  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2'

  spec.add_development_dependency "minitest", "~> 5.4.3"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "chronic"
end
