module RScript
end

require 'term/ansicolor'

load File.join(File.dirname(__FILE__), 'rscript/lexer.rb') unless RScript.const_defined? :Lexer
load File.join(File.dirname(__FILE__), 'rscript/parser_ext.rb') unless RScript.const_defined? :ParserExt
load File.join(File.dirname(__FILE__), 'rscript/parser.rb') unless RScript.const_defined? :Parser
