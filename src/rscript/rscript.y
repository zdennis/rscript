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
      stmts
      { result = Program.new val[1] }

stmts: stmt
    | stmts term { result = Statements.new val[0], val[1] }
    
    # val[0] is array of statements, val[1] is the terminator and val[2] is the raw statement
    # - we ignore the terminator
    | stmts term stmt { result = Statements.new val[0], val[2] }
    
    # | stmts indent stmts { result = Statements.new val[0], val[2] }
    # | stmts outdent term stmts { result = Statements.new val[0], val[3] }

stmt:  
    klass_def
    | klass_def Indent stmts Outdent { val.first.statements = val[2] }
    | expr { result = Statement.new val[0] }

expr: arg

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

klass_def: 
  Class id term Indent stmts { new_env ; result = ClassDefinition.new(val[1], val[4]) }
   | Class id term Outdent { new_env ; result = ClassDefinition.new(val[1]) ; pop_env val[3] }

indent: Indent { result = nil }
#     | indent Indent { result = nil }

outdent: Outdent { result = nil }
#    | outdent Outdent { puts "-"*100 ; pop_env val[0] ; result = nil }
    
id: 
  # val[0] is the raw Identifier
  Identifier { result = val[0] }
        
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
