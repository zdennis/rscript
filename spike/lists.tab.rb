#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.9
# from Racc grammer file "".
#

require 'racc/parser.rb'
module Lists
  class Parser < Racc::Parser

module_eval(<<'...end lists.y/module_eval...', 'lists.y', 21)
  def dprint(str="")
    print str if ENV["DEBUG"]
  end
  
  def dputs(str="")
    puts str if ENV["DEBUG"]
  end

  def next_token
    @q.shift
  end
  
  def parse
    # (1, (2, (3), 4), 5), 6)

    # (1, 2, 3, (1, 2, 3))

    # TEST 1
    @q = []
    # @q.push ["(", "("]
    # @q.push ["(", "("]
    # @q.push [:Number, 1]
    # @q.push [")", ")"]
    # @q.push [",", ","]
    @q.push ["(", "("]
    @q.push ["(", "("]
    @q.push ["(", "("]
    @q.push [")", ")"]
    @q.push [")", ")"]
    @q.push [")", ")"]
    # @q.push [",", ","]
    # @q.push [:Number, 2]
    # @q.push [",", ","]
    # @q.push [:Number, 3]
    # @q.push [",", ","]
    # @q.push ["(", "("]
    # @q.push [:Number, 1]
    # @q.push [",", ","]
    # @q.push [:Number, 2]
    # @q.push [",", ","]
    # @q.push [:Number, 3]
    # @q.push [")", ")"]
    # @q.push [")", ")"]

    # TEST 2
    # @q = []
    # @q.push [:Term, "("]
    # @q.push [:Number, 1]
    # @q.push [:Term, ","]
    # @q.push [:Term, "("]
    # @q.push [:Number, 2]
    # @q.push [:Term, ","]
    # @q.push [:Term, "("]
    # @q.push [:Number, 3]
    # @q.push [:Term, ","]    
    # @q.push [:Term, ")"]
    # @q.push [:Number, 4]
    # @q.push [:Term, ")"]
    # @q.push [:Term, ","]
    # @q.push [:Number, 5]
    # @q.push [:Term, ")"]
    # @q.push [:Term, ","]
    # @q.push [:Number, 6]
    # @q.push [:Term, ")"]

    @q.push [false, '$']   # is optional from Racc 1.3.7
    dputs
    dputs @q.inspect
    dputs
    __send__(Racc_Main_Parsing_Routine, _racc_setup(), false)
  end

...end lists.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
     8,     2,     4,    10,    11,     8,     2,     9,     3,     2 ]

racc_action_check = [
     2,     2,     2,     5,     5,    11,    11,     3,     1,     0 ]

racc_action_pointer = [
     6,     8,    -2,     7,   nil,    -1,   nil,   nil,   nil,   nil,
   nil,     3,   nil,   nil ]

racc_action_default = [
    -8,    -8,    -8,    -8,    -1,    -8,    -3,    -6,    -7,    14,
    -2,    -8,    -4,    -5 ]

racc_goto_table = [
     1,     6,     7,     5,   nil,   nil,   nil,   nil,   nil,   nil,
    12,    13 ]

racc_goto_check = [
     1,     3,     1,     2,   nil,   nil,   nil,   nil,   nil,   nil,
     3,     1 ]

racc_goto_pointer = [
   nil,     0,     1,    -1 ]

racc_goto_default = [
   nil,   nil,   nil,   nil ]

racc_reduce_table = [
  0, 0, :racc_error,
  2, 7, :_reduce_1,
  3, 7, :_reduce_2,
  1, 8, :_reduce_none,
  3, 8, :_reduce_4,
  3, 8, :_reduce_5,
  1, 8, :_reduce_6,
  1, 9, :_reduce_7 ]

racc_reduce_n = 8

racc_shift_n = 14

racc_token_table = {
  false => 0,
  :error => 1,
  :Number => 2,
  "(" => 3,
  ")" => 4,
  "," => 5 }

racc_nt_base = 6

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "Number",
  "\"(\"",
  "\")\"",
  "\",\"",
  "$start",
  "list",
  "elements",
  "element" ]

Racc_debug_parser = true

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'lists.y', 5)
  def _reduce_1(val, _values, result)
     result = [] 
    result
  end
.,.,

module_eval(<<'.,.,', 'lists.y', 6)
  def _reduce_2(val, _values, result)
     result = [*val[1]] 
    result
  end
.,.,

# reduce 3 omitted

module_eval(<<'.,.,', 'lists.y', 9)
  def _reduce_4(val, _values, result)
     result = Array(val[0]) + Array(val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'lists.y', 10)
  def _reduce_5(val, _values, result)
     result = [*val[0], val[2]]
    result
  end
.,.,

module_eval(<<'.,.,', 'lists.y', 11)
  def _reduce_6(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'lists.y', 15)
  def _reduce_7(val, _values, result)
     result = val[0] 
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

  end   # class Parser
  end   # module Lists


require 'pp'

if $0 == __FILE__
  puts "-"*100
  puts 'result:'
  
  v = Lists::Parser.new.parse
  pp v
end