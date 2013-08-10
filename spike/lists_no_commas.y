# racc  spike/lists_no_commas.y -v -t && ruby spike/lists_no_commas.tab.rb

class Lists::Parser
  token Number
  
rule

list: '(' ')' { result = [] }
  | '(' elements ')' { result = [*val[1]] }

elements: element 
  | elements element { result = Array(val[0]) + Array(val[1])}
  | elements list { result = [*val[0], val[1]]}
  | list { result = [val[0]] }

element: Number { result = val[0] }

---- inner
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
    @q.push ["(", "("]
    @q.push ["(", "("]
    @q.push [:Number, 1]
    @q.push [")", ")"]
    @q.push ["(", "("]
    @q.push ["(", "("]
    @q.push ["(", "("]
    @q.push [")", ")"]
    @q.push [")", ")"]
    @q.push [")", ")"]
    @q.push [:Number, 2]
    @q.push [:Number, 3]
    @q.push ["(", "("]
    @q.push [:Number, 1]
    @q.push [:Number, 2]
    @q.push [:Number, 3]
    @q.push [")", ")"]
    @q.push [")", ")"]

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

---- footer

require 'pp'

if $0 == __FILE__
  puts "-"*100
  puts 'result:'
  
  v = Lists::Parser.new.parse
  pp v
end
