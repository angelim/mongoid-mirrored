$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

require "rubygems"
require "bundler"
Bundler.setup

require 'rspec'
require 'mongoid'
require 'mongoid-mirrored'

Mongoid.configure do |config|
  name = "mongoid-mirrored-test"
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
  config.autocreate_indexes = true
end

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }

RSpec.configure do |config|
  config.mock_with :rspec
  config.after :each do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end
