# $Id$
#

class RScript::Parser
  token Class Module Method Indent Outdent Identifier Terminator Number Assign Lambda ModuleSeparator Comment HereComment CompoundAssign Comparison String Conditional

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
  
body: statements    { result = Statements.new val[0], nil }
  | statements term { result = Statements.new val[0], nil }

statements: statement { result = Statement.new val[0] }
  | statements statement { result = Statements.new val[0], val[1] }

statement: expr { result = Statement.new Expression.new(val[0], nil, nil) }
  | statement comment

expr: definition
  | assignment
  | lambda

assignment: lvalue Assign expr { result = Assignment.new Expression.new(val[0], Operator.new(val[1]), val[2]) }

lvalue: id

comment: Comment { result = Comment.new(val[0]) } 
  | HereComment { result = HereComment.new(val[0]) } 

lambda: Lambda term block { result = Block.new val[2] }

block: Indent Outdent
  | Indent body Outdent { result = Statements.new(val[1]) } #; pop_env val[2] ; }

definition: klass
  | module
  | method

klass: klass2 block { result = val[0].tap{ |klass_def| klass_def.statements = val[1] } }
  | klass2 term { result = val[0] }

klass2: Class id { result = ClassDefinition.new val[1], nil } 
  | Class id module_separator_w_identifier { result = ClassDefinition.new [val[1], val[2]], val[4] }

module: module2 term { result = val[0] }
  | module block { result = val[0].tap{ |module_def| klass_def.statements = val[1] } }

module2: Module id { result = ModuleDefinition.new(val[1], nil) }
  | Module id module_separator_w_identifier { result = ModuleDefinition.new [val[1],val[2]], nil }

module_separator_w_identifier: ModuleSeparator id { result = [val[1]] }
  | module_separator_w_identifier ModuleSeparator id  { result = [val[0], val[2]].flatten }

method: method2 term { result = val[0] }
  | method block { result = val[0].tap{ |_def| _def.statements = val[2] }}

method2: Method id { result = MethodDefinition.new val[1] }
  | Method id '.' id { result = MethodDefinition.new([val[1], val[3]]) }
  | method2 list { result = val[0].tap{ |_def| _def.parameter_list = ParameterList.from_list val[1] } }
  | method2 '(' list ')' { result = val[0].tap{ |_def| _def.parameter_list = ParameterList.from_list val[2] } }
  | method2 comment { result = val[0].tap{ |_def| _def.comment = comment } }

list: 'foo' #expr
   #expr ',' list { result = List.new val[0], val[2] }


# method_call: expr '.' list { result = MethodCall.new val[0], Operator.new(val[1]), val[2] }
#    | expr '.' '(' list ')' { result = MethodCall.new val[0], Operator.new(val[1]), val[2] }
#    | id list { result = MethodCall.new val[0], nil, val[1] }
#    | expr lambda { result = ExpressionWithBlock.new val[0], val[1] }

# list_expr: '(' list ')' { result = ParentheticalExpression.new val[1] }
#   | '[' list ']' { result = ArrayExpression.new val[1]}
#   | '[' ']' { result = ArrayExpression.new }




# line: statement
  # | definition { result = Statements.new val[0], nil }
  # | lambda
  # | comment


# expr: array

#    # | assignment
#    # | arg
#    # | method_call

# array: '[' ']' { result = ArrayExpression.new }
#   | '[' list ']' { result = ArrayExpression.new val[0] }
#   | '[' list ',' list ']'




# assignment: expr Assign expr { result = Assignment.new Expression.new(val[0], Operator.new(val[1]), val[2]) }
#    | lvalue Assign lambda { result = Assignment.new Expression.new(val[0], Operator.new(val[1]), val[2]) }

# lvalue: id

# arg: expr operator expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
#    | method_call
#    | String
#    | primary

# operator: '+' 
#    | '-' 
#    | '**'
#    | '*' 
#    | '/' 
#    | '%' 
#    | '^' 
#    | '||'
#    | '&&'
#    | '&' 
#    | '|' 
#    | Comparison
#    | CompoundAssign

# primary: literal
#    | Number { result = Rvalue.new(val[0])}


# literal: id



id: Identifier { result = Rvalue.new val[0] }
        
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
    @yydebug = false
    dprint "lexing..." 
    @q = RScript::Lexer.new.tokenize(str)
   # puts @q.map(&:inspect)
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
