$:.push File.expand_path("../lib", __FILE__)

require 'bundler'
require "rspec"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new("spec:functional") do |spec|
  spec.rspec_opts = %w(--format progress)
  spec.pattern = "spec/functional/**/*_spec.rb"
end

task :default => :spec
task :test => :spec

require 'rake/rdoctask'
require "mongoid-mirrored/version"
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongoid-mirrored #{Mongoid::Mirrored::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
