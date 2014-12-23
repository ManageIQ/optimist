require "bundler/gem_tasks"
require 'rake/testtask'
require 'coveralls/rake/task'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/test_*.rb"
end

Coveralls::RakeTask.new
