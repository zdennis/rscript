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
    # 
    # | stmts outdent

stmt:  
    klass_def
    # | indent
    # | id { result = Statement.new val[0] }
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

klass_def: Class id { result = ClassDefinition.new(val[1]) }
    #| klass_def term
    #| klass_def term Indent
    #| Class id term Indent { new_env val[3] ; result = ClassDefinition.new(val[1]) }
    #| Class id term Indent stmts

method_def: 
    Method id term Indent stmts term { new_env val[3] ; result = MethodDefinition.new(val[1]) }

# indent: Indent { result = nil }
#     | indent Indent { result = nil }
# 
# outdent: Outdent { puts "*"*100 ; pop_env val[0] ; result = nil }
#     | outdent Outdent { puts "-"*100 ; pop_env val[0] ; result = nil }
    
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
