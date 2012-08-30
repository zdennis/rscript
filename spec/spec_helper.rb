require 'rspec'
require 'pathname'
require 'pry'

$:.unshift File.dirname(__FILE__) + "/../src/"

require 'bundler'
Bundler.setup


ProjectRoot = Pathname.new File.join(File.dirname(__FILE__), "../src")
GrammarFile = ProjectRoot.join("rscript/rscript.y")
OutputFile  = ProjectRoot.join("rscript/parser.rb")

system %|racc #{GrammarFile} -v -t -o #{OutputFile}|

require 'rscript'

module ParserSpecExtensions
  def code(code)
    let(:code){ code.heredoc }
  end

  def it_outputs_as(str)
    it { should eq(str) }
  end
end

RSpec.configure do |c|
  c.mock_with :rspec
  c.extend ParserSpecExtensions
end

class String
  def heredoc
    gsub(/^\s+\|/, '')
  end
end


