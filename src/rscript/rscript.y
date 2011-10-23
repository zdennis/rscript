# $Id$
#
# convert Array-like string into Ruby's Array.

class RScript::Parser

rule

array   : '[' contents ']'
            {
              puts "new array1: #{val[1].inspect}"
              result = val[1]
            }
        | '[' ']'
            {
              puts "empty array"
              result = []
            }
        | whitespace array
        | array whitespace


# contents: ITEM
#             {
#               puts "item assign: #{val}"
#               result = val
#             }
#
#         | contents ',' ITEM
#             {
#               puts "item list: #{result.inspect} pushes #{val[2]}  of #{val.inspect}"
#               result.push val[2]
#             }
# 

# contents: 
#         | item 
#         | array ',' contents
#            { 
#               puts "item array0: #{result.inspect} of #{val.inspect}"
#               result = val.last.unshift(val.first)
#            }
#         | contents ',' array
#            { 
#               puts "item array1: #{result.inspect} of #{val.inspect}"
#               puts
#               result.push val.last
#            }
#         | contents ',' item
#             {
#               puts "item list: #{result.inspect} pushes #{val[2].inspect} of #{val.inspect}"
#               result = [result, val[2]].flatten
#             }
# item: ITEM
#           { 
#             puts "item assign: #{val}"
#             result = Item.new(val.first)
#           }

contents: 
        | whitespace contents
        | contents whitespace
        | array ',' array
        | array ',' contents
           { 
              puts "item array0: #{result.inspect} of #{val.inspect}"
              result = val.last.unshift(val.first)
           }
        | contents ',' array
           { 
              puts "item array1: #{result.inspect} of #{val.inspect}"
              puts
              result.push val.last
           }
        | terms ',' contents
           { 
              puts "item contents0: #{result.inspect} of #{val.inspect}"
              result = [val.first, val.last].compact.flatten
           }
        | contents ',' terms
            {
              puts "item list: #{result.inspect} pushes #{val[2].inspect} of #{val.inspect}"
              result = [result, val[2]].compact.flatten
            }
        | terms
            
terms: 
      | identifier
      | number

whitespace:
      | indentation
      | terminator

indentation: Indent { puts "indent: #{val.inspect}" ; result = nil }
      | Outdent { puts "outdent: #{val.inspect}"; result = nil }
            
identifier: Identifier
          { 
            puts "identifier: #{val.inspect}"
            result = Item.new(val.first)
          }

number: Number
          {
            puts "numeric: #{val.inspect}"
            result = Item.new(val.first)
          }
          
terminator: Terminator
         {
           puts "terminator: #{result.inspect} of #{val.inspect}"
           result = nil
         }
      

---- inner
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'rscript'))
  
  class Item
    def initialize(val)
      @val = val
    end
    
    def to_s
      @val
    end
  end


  def parse(str)
    @q = RScript::Lexer.new.tokenize(str)
    # str = str.strip
    # @q = []
    # until str.empty?
    #   case str
    #   when /\A\s+/
    #     str = $'
    #   when /\A\w+/
    #     @q.push [:ITEM, $&]
    #     str = $'
    #   else
    #     c = str[0,1]
    #     @q.push [c, c]
    #     str = str[1..-1]
    #   end
    # end
    # @q.push [false, '$']   # is optional from Racc 1.3.7
    puts
    puts @q.inspect
    puts
    __send__(Racc_Main_Parsing_Routine, _racc_setup(), false)
  end

  def next_token
    v = @q.shift
#    puts v.inspect
    v
  end

---- footer

if $0 == __FILE__
  src = <<EOS
[a, b,
  c, d]
EOS
  puts 'parsing:'
  print src
  puts
  puts 'result:'
  
  v = RScript::Parser.new.parse(src)
  puts
  pp v
end
