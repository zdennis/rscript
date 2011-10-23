# $Id$
#
# convert Array-like string into Ruby's Array.

class RScript::Parser

rule

program: 
  { new_env }
  stmts
  { result = val }

stmts: stmt
      
    # val[0] is array of statements, val[1] is the terminator and val[2] is the raw statement
    # - we ignore the terminator
    | stmts term stmt { result = Statements.new val[0], val[2] } 
   
stmt: id { result = Statement.new val[0] }
    
    | expr
    
expr: id operator id { result = Expression.new val[0], val[1], val[2] }

id: 
  # val[0] is the raw Identifier
  Identifier { result = val[0] } 
  
operator: '+' { result = Operator.new val[0] }

term: Terminator


---- inner
  require 'bundler'
  Bundler.setup(:development)
  require 'term/ansicolor'
  include Term::ANSIColor

  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rscript'))
  
  include ParserExt
  
  def parse(str)
    print "lexing..."
    @q = RScript::Lexer.new.tokenize(str)
    puts "done"
    # @q.push [false, '$']   # is optional from Racc 1.3.7
    puts
    puts @q.inspect
    puts
    __send__(Racc_Main_Parsing_Routine, _racc_setup(), false)
  end

  def next_token
    @q.shift
  end

---- footer

if $0 == __FILE__
  src = <<EOS.chomp
a + b
c
d
EOS
  puts "-"*100
  puts 'parsing:'
  puts src
  puts "-"*100
  puts 'result:'
  
  v = RScript::Parser.new.parse(src)
  puts
  puts "-"*100
  pp v
end
