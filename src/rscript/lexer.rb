require 'ruby-debug'

# Tokens are returned in the following structure:
#   [tag, value, lineNumber, attributes={}]
#
class RScript::Lexer
  IDENTIFIER = /^([A-z_]+)/
  WHITESPACE = /\A[^\n\S]+/
  MULTI_DENT = /\A(?:\n[^\n\S]*)+/
  NUMBER    =  /\A
                [\d]+         # any number
                (?:[\.]\d+)?  # optionally followed by a decimal and any numbers
                (?:[Ee]\d+)?  # optionally followed by exponential notiation
              /x
  
  def initialize
    @tokens = []
  end
  
  def tokenize(code)
    @line = 0

    i = 0
    process_next_chunk = -> { @chunk = code.slice(i..-1) ; @chunk != "" }

    while process_next_chunk.call
      result = identifier_token() || 
        whitespace_token() ||
        line_token() ||
        number_token()
        
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
