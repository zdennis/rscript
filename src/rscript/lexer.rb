require 'ruby-debug'

# Tokens are returned in the following structure:
#   [tag, value, lineNumber, attributes={}]
#
class RScript::Lexer
  IDENTIFIER   = /\A([A-z_]+)/
  WHITESPACE   = /\A[^\n\S]+/
  MULTI_DENT   = /\A(?:\n[^\n\S]*)+/
  NUMBER       =  /\A
                  [\d]+           # any number
                  (?:[\.]\d+)?    # optionally followed by a decimal and any numbers
                  (?:[Ee]\d+)?    # optionally followed by exponential notiation
                 /x
  SQUOTESTR    = /\A'
                  [^\\']*         # single quote followed by anything but escaped quote
                  (?:\\.[^\\']*)* # followed optionally by escaped dot any anything but escaped quote
                  '               
                 /mx
  DQUOTESTR    = /\A"
                 [^\\"]*         # single quote followed by anything but escaped quote
                 (?:\\.[^\\"]*)* # followed optionally by escaped dot any anything but escaped quote
                 "               
                 /mx
  HERE_COMMENT = /\A(###+\n(.*?)###\s*\n)/m
  COMMENT      = /\A(#+([^\#]*))$/
  OPERATOR     = /\A (?:
                  [+-\/*%]      # arithmetic operators
                 )/x
  
  def initialize(options={})
    @tokens = []
    @infinite = options[:infinite]
  end
  
  def tokenize(code)
    @line = 0
    @indents = []
    @indent = 0

    count = 0

    i = 0
    process_next_chunk = -> { @chunk = code.slice(i..-1) ; @chunk != "" }

    while process_next_chunk.call
      result = identifier_token() || 
        whitespace_token() ||
        comment_token() ||
        line_token() ||
        number_token() ||
        string_token() ||
        literal_token()
      
      count += 1
      raise "Infinite loop (#{@infinite}) on unknown: #{@chunk}" if @infinite && @infinite == count
        
      i += result.to_i
    end
    
    @tokens
  end
  
  private
  
  # Helper
  def count(content, what)
    content.scan(what).length
  end
  
  # Matches single and multi-line comments.
  def comment_token
    if md=HERE_COMMENT.match(@chunk)
      input, comment, body = md.to_a
      token :HereComment, body
      token :Terminator, "\n"
      @line += count(comment, "\n")
      return comment.length
    elsif md=COMMENT.match(@chunk)
      input, comment, body = md.to_a
      token :Comment, body
      return comment.length
    end

    return nil
  end
  
  def literal_token
    return nil unless md=OPERATOR.match(@chunk)
    operator = md.to_a[0]
    token :Operator, operator
    return operator.length
  end
  
  def identifier_token
    return nil unless md=IDENTIFIER.match(@chunk)
    input, id = md.to_a
    
    tag = :Identifier
    token tag, id

    input.length
  end
  
  # Matches num_newlines, indents, and outdents. Determines which is which.
  def line_token
    return nil unless md = MULTI_DENT.match(@chunk)

    @tokens.last.push newLine: true
    token :Terminator, "\n"

    indent = md.to_a[0]
    num_newlines = count(indent, "\n")
    spaces = indent.length - num_newlines

    @line += num_newlines

    movement = spaces - @indent
    if movement > 0
      @indents.push movement
      token :Indent, movement
    elsif movement < 0
      outdent_token movement.abs, num_newlines
    end

    @indent += movement
    indent.length
  end
  
  def outdent_token(movement, num_newlines)
    while movement > 0
      if indented=@indents.last
        movement -= indented
      else
        raise "Lexer error. No indentation to outdent."
        # movement = 0
      end
      
      token :Outdent, indented
    end
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
      return nil unless md = SQUOTESTR.match(@chunk)
      string = md.to_a[0]
      token :String, string
      return string.length
    when '"'
      return nil unless md = DQUOTESTR.match(@chunk)
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
