require 'rake'
require 'rake/testtask'
require "bundler/gem_tasks"

desc 'Run tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task :default => :test
