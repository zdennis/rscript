# $Id$
#

class RScript::Parser
  token Class Method Indent Outdent Identifier Terminator

  prechigh
    left '**' '*' '/' '%'
    left '+' '-'
    left '&&' '||'
    left '|' '^' '&'
  preclow

  
rule

program: none
    | { new_env }
      body
      { result = Program.new val[1] }
    
body: line { result = Statement.new val[0] }
    | body term line { result = Statements.new val[0], val[2] }
    | body term { result = Statements.new val[0], nil }

line: expr { result = Statement.new val[0] }

expr: arg
   | klass

arg: arg '+'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '-'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '**' arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '*'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '/'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '%'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '^'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '||' arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '&&' arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '&'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | arg '|'  arg { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | primary

primary: literal

literal: id

block: Indent Outdent
   | Indent body Outdent { result = Statements.new(val[1]) ; pop_env val[2] }

klass: Class id term block { new_env ; result = ClassDefinition.new(val[1], val[3]) }
   | Class id term { new_env ; result = ClassDefinition.new(val[1], nil) }
 
id: Identifier { result = val[0] }
        
term: Terminator

none: { result = Nothing.new }


---- inner
  include ParserExt
  
  def dprint(str="")
    print str if ENV["DEBUG"]
  end
  
  def dputs(str="")
    puts str if ENV["DEBUG"]
  end
  
  def parse(str)
    dprint "lexing..." 
    @q = RScript::Lexer.new.tokenize(str)
    dputs "done"
    # @q.push [false, '$']   # is optional from Racc 1.3.7
    dputs
    dputs @q.inspect
    dputs
    __send__(Racc_Main_Parsing_Routine, _racc_setup(), false)
  end

  def next_token
    @q.shift
  end

---- footer

if $0 == __FILE__
  src = <<EOS.chomp
class Foo
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
