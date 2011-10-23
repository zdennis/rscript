require 'rspec'
require 'pathname'

$:.unshift File.dirname(__FILE__) + "/../src/"

require 'bundler'
Bundler.setup


ProjectRoot = Pathname.new File.join(File.dirname(__FILE__), "../src")
GrammarFile = ProjectRoot.join("rscript/rscript.y")
OutputFile  = ProjectRoot.join("rscript/parser.rb")

system %|racc #{GrammarFile} -o #{OutputFile}|

require 'rscript'

RSpec.configure do |c|
  c.mock_with :rspec
end

