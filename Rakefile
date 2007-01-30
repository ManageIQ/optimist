# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'trollop'

Hoe.new('trollop', Trollop::VERSION) do |p|
  p.rubyforge_name = 'trollop'
  p.author = "William Morgan"
  p.summary = "Trollop is YAFCLAP --- yet another fine commandline argument processing library for Ruby. Trollop is designed to provide the maximal amount of GNU-style argument processing in the minimum number of lines of code (for you, the programmer)."
  p.description = p.paragraphs_of('README.txt', 3..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[2].gsub(/^\s+/, "")
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.email = "wmorgan-trollop@masanjin.net"
end

## is there really no way to make a rule for this?
WWW_FILES = %w(www/index.html README.txt FAQ.txt)

task :upload_webpage => WWW_FILES do |t|
  sh "scp -C #{t.prerequisites * ' '} wmorgan@rubyforge.org:/var/www/gforge-projects/trollop/"
end

# vim: syntax=Ruby
