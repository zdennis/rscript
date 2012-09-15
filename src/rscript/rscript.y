# $Id$
#

class RScript::Parser
  token Class Module Method Indent Outdent Identifier Terminator Number Assign Lambda ModuleSeparator 

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
    | body term { result = Statements.new val[0], nil }
    | body line { result = Statements.new val[0], val[1] }

line: expr { result = Statement.new val[0] }
   | definition
   | lambda

definition: klass
   | module
   | method

expr: '(' list ')' { result = ParentheticalExpression.new val[1] }
   | assignment
   | arg

assignment: expr Assign line { result = Statement.new Expression.new(val[0], Operator.new(val[1]), val[2]) }
   | expr Assign lambda { result = Statement.new Expression.new(val[0], Operator.new(val[1]), val[2]) }

arg: expr '+'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '-'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '**' expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '*'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '/'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '%'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '^'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '||' expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '&&' expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '&'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | expr '|'  expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
   | method_call
   | primary

method_call: expr '.'  expr { result = MethodCall.new val[0], Operator.new(val[1]), val[2] }
   | id list { result = MethodCall.new val[0], nil, val[1] }
   | expr lambda { result = ExpressionWithBlock.new val[0], val[1] }

list: expr
   | expr ',' list { result = List.new val[0], val[2] }

primary: literal
   | Number { result = Rvalue.new(val[0])}

lambda: Lambda term block { result = Block.new val[2] }

literal: id

block: Indent Outdent
   | Indent body Outdent { result = Statements.new(val[1]) } #; pop_env val[2] ; }

module_separator_w_identifier: module_separator_w_identifier ModuleSeparator id  { result = [val[0], val[2]].flatten }
   | ModuleSeparator id { result = [val[1]] }

klass: Class id module_separator_w_identifier term block { result = ClassDefinition.new([val[1], val[2]], val[4], ) }
   | Class id module_separator_w_identifier term { result = ClassDefinition.new([val[1],val[2]], nil) }
   | Class id term block { result = ClassDefinition.new(val[1], val[3]) }
   | Class id term { result = ClassDefinition.new(val[1], nil) }
   | Class id { result = ClassDefinition.new(val[1], nil) }

module: Module id module_separator_w_identifier term block { result = ModuleDefinition.new([val[1],val[2]], val[4]) }
   | Module id module_separator_w_identifier term { result = ModuleDefinition.new([val[1],val[2]], nil) }
   | Module id term block { result = ModuleDefinition.new(val[1], val[3]) }
   | Module id term { result = ModuleDefinition.new(val[1], nil) }
   | Module id { result = ModuleDefinition.new(val[1], nil) }

method: Method id '.' id term block  { result = MethodDefinition.new([val[1], val[3]], val[5]) }
   | Method id '.' id term { result = MethodDefinition.new([val[1], val[3]])}
   | Method id '.' id { result = MethodDefinition.new([val[1], val[3]])}
   | Method id term block { result = MethodDefinition.new(val[1], val[3]) }
   | Method id term { result = MethodDefinition.new(val[1])}
   | Method id '(' list ')' term { result = MethodDefinition.new val[1], nil, ParameterList.from_list(val[3]) }
   | Method id '(' list ')' term block { result = MethodDefinition.new val[1], val[6], ParameterList.from_list(val[3]) }
   | Method id list term { result = MethodDefinition.new(val[1], nil, val[2]) }
   | Method id { result = MethodDefinition.new(val[1])}

id: Identifier { result = Rvalue.new(val[0]) }
        
term: Terminator

none: { result = Nothing.new }

---- header
  require File.dirname(__FILE__) + "/../rscript"


---- inner
  include ParserExt
  
  def dprint(str="")
 #   print str if ENV["DEBUG"]
  end
  
  def dputs(str="")
#    puts str if ENV["DEBUG"]
  end
  
  def parse(str)
#    @yydebug = true
    dprint "lexing..." 
    @q = RScript::Lexer.new.tokenize(str)
#    puts @q.map(&:inspect)
    dputs "done"
    # @q.push [false, '$']   # is optional from Racc 1.3.7
    dputs
#    dputs @q.inspect
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
  class Bar
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
