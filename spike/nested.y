class Experimental::Parser
  token Block Indent Term Outdent
  
rule

program: none
    | stmts { puts val.inspect ; result = val[0] }

stmts: stmt { puts val.inspect ; result = val[0] }
  | stmts stmt

stmt: block
  | stmt Indent { result = val }
  | stmt term { result = val }
  | stmt Outdent
  
block: Block { puts val.inspect ; result = val[0] }
  
term: Term { result = val[0] }
      
none: # nothing



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
    @q = []
    @q.push [:Block, "block"]
    @q.push [:Term, "\n"]
    @q.push [:Indent, 2]
    @q.push [:Block, "block"]
    @q.push [:Term, "\n"]
    @q.push [:Outdent, 2]
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
  
  v = Experimental::Parser.new.parse
  pp v
end
