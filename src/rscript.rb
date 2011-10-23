module RScript
end

require 'term/ansicolor'

require File.join(File.dirname(__FILE__), 'rscript/lexer')
require File.join(File.dirname(__FILE__), 'rscript/parser_ext')
require File.join(File.dirname(__FILE__), 'rscript/parser')
