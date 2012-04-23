require 'rubygems'
$:.unshift "lib"
require 'trollop'
require 'rake/gempackagetask.rb'

spec = Gem::Specification.new do |s|
 s.name = "trollop"
 s.version = Trollop::VERSION
 s.date = Time.now
 s.email = "wmorgan-trollop@masanjin.net"
 s.authors = ["William Morgan"]
 s.summary = "Trollop is a commandline option parser for Ruby that just gets out of your way."
 s.homepage = "http://trollop.rubyforge.org"
 s.files = %w(lib/trollop.rb test/test_trollop.rb) + Dir["*.txt"]
 s.executables = []
 s.rubyforge_project = "trollop"
 s.description = "Trollop is a commandline option parser for Ruby that just
gets out of your way. One line of code per option is all you need to write.
For that, you get a nice automatically-generated help page, robust option
parsing, command subcompletion, and sensible defaults for everything you don't
specify."
end

WWW_FILES = FileList["www/*"] + %w(README.txt FAQ.txt)
task :upload_webpage => WWW_FILES do |t|
  sh "rsync -Paz -essh #{t.prerequisites * ' '} wmorgan@rubyforge.org:/var/www/gforge-projects/trollop/"
end

task :rdoc do |t|
  sh "rdoc lib README.txt History.txt -m README.txt"
end

task :upload_docs => :rdoc do |t|
  sh "rsync -az -essh doc/* wmorgan@rubyforge.org:/var/www/gforge-projects/trollop/trollop/"
end

task :test do
  sh %!ruby -w -Ilib:ext:bin:test -e 'require "rubygems"; require "test/unit"; require "./test/test_trollop.rb"'!
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

# vim: syntax=ruby
