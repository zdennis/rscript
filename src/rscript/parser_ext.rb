module RScript::ParserExt
  def self.included(klass)
    klass.send :extend, ClassMethods
  end
  
  module ClassMethods
    def new_env
      @env ||= Environment.new
    end

    def env
      @env
    end
  end
  
  def new_env
    self.class.new_env
  end
  
  def env
    self.class.env
  end
  
  class Environment
  end
  
  class Node
    def initialize
      @env = RScript::Parser.env
    end
    
    def as_ruby(token)
      return token.to_ruby if Node === token
      return token.val if ::RScript::Lexer::Token === token
      return "" if token.nil?
      raise NotImplementedError, "Do not know how to convert #{token.inspect} to ruby"
    end
    
    def to_ruby
      raise NotImplementedError, "Must override #to_ruby in #{self.class}"
    end
  end
  
  class Program < Node
    def initialize(statements, term=nil)
      @statements = statements
      @term = term
    end
    
    def to_ruby
      @statements.to_ruby 
    end
  end
  
  class Nothing < Node
    def to_ruby
      ""
    end
  end
  
  class Statements < Node
    def initialize(head, tail=nil)
      super()
      @head, @tail = head, tail
    end
    
    def to_ruby
      Array.new.tap do |arr|
        arr << as_ruby(@head)

        case @tail
        when nil # no-op
        when Node
          arr << @tail.to_ruby
        else
          # assume we have a Lexer::Token
          arr << "" if @tail.val == "\n"
        end
      end.join("\n")
    end
  end
  
  class Statement < Node
    def initialize(statement)
      super()
      @statement = statement
    end
    
    def to_ruby
      @statement.val
    end
  end
  
  class Expression < Node
    def initialize(head, op, tail)
      super()
      @head, @op, @tail = head, op, tail
    end
    
    def to_ruby
      Array.new.tap do |arr|
        arr << as_ruby(@head)
        arr << @op.to_ruby
        arr << as_ruby(@tail)
      end.join(" ")
    end
  end
  
  class Operator < Node
    def initialize(op)
      @op = op
    end
    
    def to_ruby
      # assume we have a Lexer::Token
      @op.val
    end
  end
  
end