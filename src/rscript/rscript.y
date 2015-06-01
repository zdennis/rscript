# $Id$
#

class RScript::Parser
  token Class Module Method Indent Outdent Identifier Terminator Number Assign Lambda ModuleSeparator Comment HereComment CompoundAssign Comparison String And Or Not

  prechigh
    left '**' '*' '/' '%'
    left '+' '-'
    left '&&' '||'
    left '|' '^' '&'
    right Not
    left And Or
  preclow

rule

program:
  { new_env }
  body
  { result = Item(:program, left: val[1]) }
  
body: top_statements

top_statements: none
  | top_statement
  | top_statements term
  | top_statements term top_statement { result = Item(:statements, left: val[0], right: val[2])}

top_statement: statement { result = Item(:statement, left: val[0])}

# foo if true
# bar unless false
# a = b
# a.bar = 5
# a[5] = 6
# a(1,2,3)
# a 1,2,3
# bar::foo(1,2,3)
# bar::foo 1,2,3
# bar::foo = 5
statement: 
  command_assignment
  | expr 
  # mlhs '=' command_call

# a = b = c(1,2,3)
# b = bar(a, 5, 6)
command_assignment: lvalue Assign command_assignment { result = Item(:assignment, left: val[0], right: val[2]) }
  | lvalue Assign command_call { result = Item(:assignment, left: val[0], right: val[2]) }
  | lvalue Assign primary  { result = Item(:assignment, left: val[0], right: val[2]) }

# 1 + 1
# (2 + 3)
# foo
# foo( bar )
# not foo
# !foo
# -> bar
expr: 
  command_call # { result = Item(:call, value: val[0]) }
  | expr And expr { result = Item(:and_conditional, left: val[0], right: val[2]) }
  | expr Or expr { result = Item(:or_conditional, left: val[0], right: val[2]) }
#  | Not optional_newline expr { result = Item(:not, left: val[2]) }
#  | lambda
  | arg

arg: lhs '=' arg { result = Item(:assignment, left: lhs, right: arg) }
  | primary
  # | arg '-' arg
  # | arg '*' arg
  # | arg '' arg

lhs: user_variable
  # | keyword_variable
  # | primary_value '[' optional_call_args ']'
  # | primary_value '.' id
  # | primary_value '::' id
  # | primary_value ':: 

user_variable: id
  # | ivar
  # | gvar
  # | constant
  # | cvar

optional_newline: none
  | term

command_call: command
   # | block_ca
   # expr '.' list { result = MethodCall.new val[0], Operator.new(val[1]), val[2] }
   # | expr '.' '(' list ')' { result = MethodCall.new val[0], Operator.new(val[1]), val[2] }
   # | id list { result = MethodCall.new val[0], nil, val[1] }
   # | id '.' '(' list ')'
   # | id lambda { result = ExpressionWithBlock.new val[0], val[1] }
   # lambda
   # command_call lambda { result = ExpressionWithBlock.new val[0], val[1] }

# foo b
# foo 1
# foo bar 1
# foo bar baz 
# foo bar baz 99
command: function_call command_args { result = Item(:function_call, left: val[0], right: val[1]) }
  #| function_call command_args block
  # | primary '.' ...

function_call: operation

block_call: command block
  # | co

operation: id
  # | constant
  # | FID?

command_args: call_args

call_args: command
  | primary

lvalue: id

comment: Comment { result = Item.new(:comment, left: val[0]) } 
  | HereComment { result = Item.new(:hereComment, left: val[0]) } 

lambda: Lambda term block { result = Item.new(:lambda, left: val[2]) } 

block: Indent Outdent
  | Indent body Outdent { result = Item.new(:block, left: val[1]) }  # pop_env?

definition: klass
  | module
  | method

klass: klass2 block { result = val[0].tap{ |_def| _def.set(:body, val[1]) } }
  | klass2 term { result = val[0] }

klass2: Class id { result = Item(:klassDef, name: val[1]) } 
  | Class id module_separator_w_identifier { result = Item(:klassDef, name: val[1], separator: val[2]) }

module: module2 term { result = val[0] }
  | module block { result = val[0].tap{ |_def| _def.set(:body, val[1]) } }

module2: Module id { result = Item(:moduleDef, name: val[1]) }
  | Module id module_separator_w_identifier { result = Item(:moduleDef, name: val[1], separator: val[2]) }

module_separator_w_identifier: ModuleSeparator id { result = [val[1]] }
  | module_separator_w_identifier ModuleSeparator id  { result = [val[0], val[2]].flatten }

method: method2 term { result = val[0] }
  | method block { result = val[0].tap{ |_def| _def.set(:body, val[1]) } }

method2: Method id { result = Item(:methodDef, name: val[1]) }
  | Method id '.' id { result = Item(:methodDef, name: [val[1], val[3]])  }
  | method2 list { result = val[0].tap{ |_def| _def.set(:argList, val[1]) } }
  | method2 '(' list ')' { result = val[0].tap{ |_def| _def.set(:argList, val[1]) } }
  | method2 comment { result = val[0].tap{ |_def| _def.set(:comment, val[1]) } }

list: expr ',' list { result = List.new val[0], val[2] }

# arg: expr operator expr { result = Expression.new val[0], Operator.new(val[1]), val[2] }
# #   | method_call
#    | String
#    | primary

operator: '+' 
   | '-' 
   | '**'
   | '*' 
   | '/' 
   | '%' 
   | '^' 
   | '||'
   | '&&'
   | '&' 
   | '|' 
   | Comparison
   | CompoundAssign

primary: literal
   | Number { result = Item(:number, left: val[0]) }

literal: id

id: Identifier { result = Item(:identifer, left: val[0]) }
        
term: Terminator

none: { result = Item(:nothing, left: val[0]) }


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

    STDOUT.puts "--- lex tokens", @q.map(&:inspect), "--- end lex tokens"
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
