#!/usr/bin/env rake
require 'bundler'
require "bundler/gem_tasks"
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'spec'
  test.pattern = 'spec/*.rb'
  test.verbose = true
end

task :default => :test