require "bundler/gem_tasks"
require 'rake/testtask'
require 'coveralls/rake/task'

WWW_FILES = FileList["www/*"] + %w(README.txt FAQ.txt)
task :upload_webpage => WWW_FILES do |t|
  sh "rsync -Paz -essh #{t.prerequisites * ' '} wmorgan@rubyforge.org:/var/www/gforge-projects/trollop/"
end

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/test_*.rb"
end

Coveralls::RakeTask.new


# vim: syntax=ruby
