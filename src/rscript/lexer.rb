# Tokens are returned in the following structure:
#   [tag, value, lineNumber, attributes={}]
#
class RScript::Lexer
  IDENTIFIER   = /\A(@?[A-Za-z_]+[A-Za-z_0-9]*)/
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
                 [^\\"]*          # single quote followed by anything but escaped quote
                 (?:\\.[^\\"]*)*  # followed optionally by escaped dot any anything but escaped quote
                 "               
                 /mx
  HERE_COMMENT = /\A(###+\s*\n(.*?)###+\s*\n?)/m
  COMMENT      = /\A(#+(.*?)\s*)$/
  OPERATOR     = /\A 
                  (?: [+-\/*%]=                 # compound assignment
                    | \*\*                      # math to the power of
                    | ->                        # lambda declaration
                    | [+-\/*%]                  # arithmetic
                    | [\(\)] | [\[\]]           # parens, brackets
                    | << | >>                   # bit-shift
                    | != | <= | >= | == | < | > # comparison
                    | [=]                       # assignment
                    | \|\| | && | & | \| | \^   # logic
                    | \!                        # remainder of unary operators
                    | ::                        # module separator
                  )/x
                 
  ASSIGNMENT_OPERATORS = %w( = )
  COMPOUND_ASSIGNMENT_OPERATORS = %w( += -= /= *= )
  COMPARISON_OPERATORS = %w( < <= == >= > != )
  LOGIC_OPERATORS = %w( || && | & ^ )
  SHIFT_OPERATORS = %w( << >> )
  UNARY_OPERATORS = %w( - + ! )
  LAMBDA_OPERATORS = %w( -> )
  MODULE_SEPARATOR = "::"
  
  RESERVED_IDENTIFIER_TAGS = {
    class:  :Class,
    module: :Module,
    def:    :Method,
    if:     :Conditional,
    unless: :Conditional,
    else:   :Conditional,
    and:    :And,
    or:     :Or,
    not:    :Not
  }
  
  def initialize(options={})
    @infinite = options[:infinite]
  end
  
  def tokenize(code)
    @tokens = []
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
    
    #token :Terminator, "\n" if @tokens.last && @tokens.last[0] != :Terminator
    
#    puts @tokens.inspect
    @tokens
  end
  
  private
  
  # Helper
  def count(content, what)
    content.scan(what).length
  end
  
  def peek
    @chunk[1]
  end
  
  # Matches single and multi-line comments.
  def comment_token
    if md=HERE_COMMENT.match(@chunk)
      input, comment, body = md.to_a
      token :HereComment, body, :newLine => true
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

    if COMPOUND_ASSIGNMENT_OPERATORS.include?(operator)
      token :CompoundAssign, operator
    elsif ASSIGNMENT_OPERATORS.include?(operator)
      token :Assign, operator
    elsif COMPARISON_OPERATORS.include?(operator)
      token :Comparison, operator
    elsif LOGIC_OPERATORS.include?(operator)
      token operator, operator
    elsif SHIFT_OPERATORS.include?(operator)
      token :Shift, operator
    # elsif UNARY_OPERATORS.include?(operator) && (peek =~ NUMBER || peek =~ IDENTIFIER)
    #   token :Unary, operator
    elsif LAMBDA_OPERATORS.include?(operator)
      token :Lambda, operator
    elsif MODULE_SEPARATOR.include?(operator)
      token :ModuleSeparator, operator
    else
      token operator, operator
    end
    return operator.length
  end
  
  def identifier_token
    return nil unless md=IDENTIFIER.match(@chunk)
    input, id = md.to_a
    tag = RESERVED_IDENTIFIER_TAGS[id.to_sym] || :Identifier
    token tag, id
    input.length
  end
  
  # Matches num_newlines, indents, and outdents. Determines which is which.
  def line_token
    return nil unless md = MULTI_DENT.match(@chunk)

    @tokens.last.last.push newLine: true
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
  
  # Matches single and double quoted strings
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
  
  def token(tag, value, attrs={})
    @tokens.push [tag, Token.new(value, @line, attrs)]
  end
  
  class Token
    include Comparable
    include Term::ANSIColor
    
    attr_reader :tag, :lineno, :attrs
    
    def initialize(tag, lineno, attrs={})
      @tag = tag
      @lineno = lineno
      @attrs = attrs
    end
    
    def push(attrs)
      @attrs.merge! attrs
    end

    def inspect
      "'#{tag}'"
    end
    
    def to_s
      green("Token(#{tag.inspect} on #{lineno})")
    end
    
    def length
      to_s.length
    end
    
    def <=>(other)
      return -1 if self.class != other.class
      return 0 if [tag, lineno, attrs] == [other.tag, other.lineno, other.attrs]
      -1
    end
  end
end
