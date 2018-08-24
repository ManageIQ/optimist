# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "trollop"
  spec.version       = "2.9.9"
  spec.authors       = ["William Morgan", "Keenan Brock"]
  spec.email         = "keenan@thebrocks.net"
  spec.summary       = "Trollop is a commandline option parser for Ruby that just gets out of your way."
  spec.description   = "Trollop is a commandline option parser for Ruby that just gets out of your way.

**DEPRECATION** This gem has been renamed to optimist and will no longer be supported. Please switch to optimist as soon as possible."
  spec.homepage      = "http://manageiq.github.io/optimist/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.metadata    = {
    "changelog_uri" => "https://github.com/ManageIQ/optimist/blob/master/History.txt",
    "source_code_uri" => "https://github.com/ManageIQ/optimist/",
    "bug_tracker_uri" => "https://github.com/ManageIQ/optimist/issues",
  }

  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.4.3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "chronic"

  spec.post_install_message = <<-MESSAGE
!    The 'trollop' gem has been deprecated and has been replaced by 'optimist'.
!    See: https://rubygems.org/gems/optimist
!    And: https://github.com/ManageIQ/optimist
  MESSAGE
end
