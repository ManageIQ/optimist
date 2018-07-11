# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "trollop"
  spec.version       = "2.1.3"
  spec.authors       = ["William Morgan", "Keenan Brock"]
  spec.email         = "keenan@thebrocks.net"
  spec.summary       = "Trollop is a commandline option parser for Ruby that just gets out of your way."
  spec.description   = "Trollop is a commandline option parser for Ruby that just
gets out of your way. One line of code per option is all you need to write.
For that, you get a nice automatically-generated help page, robust option
parsing, command subcompletion, and sensible defaults for everything you don't
specify."
  spec.homepage      = "http://manageiq.github.io/trollop/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.metadata    = {
    "changelog_uri" => "https://github.com/ManageIQ/trollop/blob/master/History.txt",
    "source_code_uri" => "https://github.com/ManageIQ/trollop/",
    "bug_tracker_uri" => "https://github.com/ManageIQ/trollop/issues",
  }

  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.4.3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "chronic"
end
