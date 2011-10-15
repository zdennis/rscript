require 'ruby-debug'

# Tokens are returned in the following structure:
#   [tag, value, lineNumber, attributes={}]
#
class RScript::Lexer
  IDENTIFIER = /\A([A-z_]+)/
  WHITESPACE = /\A[^\n\S]+/
  MULTI_DENT = /\A(?:\n[^\n\S]*)+/
  NUMBER    =  /\A
                [\d]+           # any number
                (?:[\.]\d+)?    # optionally followed by a decimal and any numbers
                (?:[Ee]\d+)?    # optionally followed by exponential notiation
               /x
  SIMPLESTR  = /\A'
                [^\\']*         # single quote followed by anything but escaped quote
                (?:\\.[^\\']*)* # followed optionally by escaped dot any anything but escaped quote
                '               
               /mx
  
  def initialize(options={})
    @tokens = []
    @infinite = options[:infinite]
  end
  
  def tokenize(code)
    @line = 0

    count = 0

    i = 0
    process_next_chunk = -> { @chunk = code.slice(i..-1) ; @chunk != "" }

    while process_next_chunk.call
      result = identifier_token() || 
        whitespace_token() ||
        line_token() ||
        number_token() ||
        string_token()
      
      count += 1
      raise "Infinite loop (#{@infinite})" if @infinite && @infinite == count
        
      i += result.to_i
    end
    
    @tokens
  end
  
  private
  
  # Helper
  def count(content, what)
    content.scan(what).length
  end
  
  
  def identifier_token
    return nil unless md=IDENTIFIER.match(@chunk)
    input, id = md.to_a
    
    tag = :Identifier
    token tag, id

    input.length
  end
  
  # Matches newlines, indents, and outdents. Determines which is which.
  def line_token
    return nil unless md = MULTI_DENT.match(@chunk)
    indent = md.to_a[0]
    @line += count(indent, "\n")
    
    @tokens.last.push newLine: true
    
    token :Terminator, "\n"
    
    indent.length
  end
  
  # Matches numbers, including decimals, and exponential notation.
  def number_token
    return nil unless md = NUMBER.match(@chunk)
    number = md.to_a[0]
    token :Number, number
    number.length
  end
  
  # Matches single quoted strings
  def string_token
    case @chunk[0]
    when "'"
      return nil unless md =SIMPLESTR.match(@chunk)
      string = md.to_a[0]
      token :String, string
      return string.length
    else
      return nil
    end
  end
  
  # Matches and consumes non-meaningful whitespace.
  def whitespace_token
    return nil unless md=WHITESPACE.match(@chunk)
    input = md.to_a[0]
    input.length
  end
  
  def token(tag, value)
    @tokens.push [tag, value, @line]
  end
end
