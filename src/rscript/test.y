# $Id$
#
# convert Array-like string into Ruby's Array.

class ArrayParser

rule

array   : '[' contents ']'
            {
              result = val[1]
            }
        | '[' ']'
            {
              result = []
            }

contents: ITEM
            {
              result = val
            }
        | contents ',' ITEM
            {
              result.push val[2]
            }

---- inner
  class Item
    def initialize(val)
      @val = val
    end
  end

  def parse(str)
    str = str.strip
    @q = []
    until str.empty?
      case str
      when /\A\s+/
        str = $'
      when /\A\w+/
        @q.push [:ITEM, Item.new($&)]
        str = $'
      else
        c = str[0,1]
        @q.push [c, Item.new(c)]
        str = str[1..-1]
      end
    end
    @q.push [false, '$']   # is optional from Racc 1.3.7
    
    __send__(Racc_Main_Parsing_Routine, _racc_setup(), false)
    #do_parse
  end

  def next_token
    @q.shift
  end

---- footer

if $0 == __FILE__
  src = <<EOS
[
  a, b, c,
  d,
  e ]
EOS
  puts 'parsing:'
  print src
  puts
  puts 'result:'
  p ArrayParser.new.parse(src)
end
