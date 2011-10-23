require 'rspec'

$:.unshift File.dirname(__FILE__) + "/../src/"

require 'bundler'
Bundler.setup

require 'rscript'

RSpec.configure do |c|
  c.mock_with :rspec
end