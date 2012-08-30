module RScript::ParserExt
  def self.included(klass)
    klass.send :extend, ClassMethods
  end
  
  module ClassMethods
    def new_env(scoping_token=nil)
      top = Environment.new(@env)
      if top.prev
        top.indentation = top.prev.indentation + 2
      else 
        top.indentation = 0
      end
      @env = top
    end
    
    def pop_env(scoping_token=nil)
      if @env.nil?
        raise "SyntaxError: Unexpected end of scoping"
      end
      @env = @env.prev
    end

    def env
      @env
    end
  end
  
  def new_env(*args)
    self.class.new_env(*args)
  end
  
  def env
    self.class.env
  end
  
  def pop_env(*args)
    self.class.pop_env(*args)
  end
  
  class Environment
    attr_accessor :indentation
    attr_accessor :prev
    
    def initialize(prev=nil)
      @prev = prev
      @indentation = 0
    end
  end
  
  class Node
    attr_reader :env
    
    def initialize
      @env = Environment.new
    end
    
    def as_ruby(token)
      return token.to_ruby if Node === token
      return token.tag if ::RScript::Lexer::Token === token
      return nil if token.nil?
      raise NotImplementedError, "Do not know how to convert #{token.inspect} to ruby"
    end
    
    def to_ruby
      raise NotImplementedError, "Must override #to_ruby in #{self.class}"
    end

    def set_prev(prev)
      env.prev = prev
    end

    def block_statement?
      false
    end

    def increment_indentation
    end

    def space(str, env)
      spacing = env.nil? ? 0 : env.indentation
      [" " * spacing, str].join
    end
  end
  
  class Program < Node
    def initialize(statements, term=nil)      
      @statements = statements
      @term = term
      super()
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
    attr_reader :head, :tail  

    def initialize(head, tail=nil)
      super()
      @head, @tail = head, tail
    end

    def set_prev(prev)
      [@head, @tail].flatten.compact.each{ |t| t.set_prev(prev) }
    end

    def increment_indentation
      [@head, @tail].flatten.compact.each{ |t| t.increment_indentation } ; true
    end
    
    def to_ruby
      Array.new.tap do |arr|
        arr << as_ruby(@head)

        case @tail
        when nil # no-op
        when Node
          arr << "" if @tail.block_statement?
          arr << as_ruby(@tail)
        else
          # assume we have a Lexer::Token
          arr << "" if @tail.tag == "\n"
        end
      end.join("\n")
    end
  end

  class Rvalue < Node
    def initialize(token)
      super()
      @token = token
    end

    def to_ruby
      as_ruby(@token)
    end
  end

  class Statement < Node
    def initialize(statement)
      super()
      if statement.is_a?(Node)
        @statement = statement
      else
        @statement = Statement.new(Rvalue.new(statement))
      end
    end

    def block_statement?
      @statement.block_statement?
    end

    def increment_indentation
      if @statement && !@statement.is_a?(Rvalue) && !@statement.is_a?(Expression)
        #puts "trying indenting #{as_ruby(@statement)}"
        @statement.increment_indentation
      else
        #puts "indenting #{as_ruby(@statement)} to #{env.indentation + 2}"
        env.indentation += 2
      end
      true
    end
    
    def to_ruby
      if @statement.is_a?(Rvalue) || @statement.is_a?(Expression)
        space(@statement.to_ruby, env)
      else
        as_ruby(@statement)
      end
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
      @op.tag
    end
  end
  
  class LogicOp < Operator
  end
  
  class ClassDefinition < Node
    attr_accessor :statements
    
    def initialize(name, statements=nil)
      @name, @statements = name, statements
      super()
      if @statements
        @statements.set_prev(env) 
        @statements.increment_indentation
      end
    end

    def block_statement?
      true
    end    

    def increment_indentation
      env.indentation += 2
      [statements].flatten.compact.each{ |t| t.increment_indentation }      
      true
    end
    
    def to_ruby
      results = Array.new.tap do |arr|
        arr << space("class #{as_ruby(@name)}", env)
        arr << as_ruby(statements) if statements
        arr << space("end", env)
      end.compact.join("\n")
      results
    end    
  end
  
  class MethodDefinition < Node
    attr_reader :statements

    def initialize(name, statements=nil)
      @name, @statements = name, statements
      super()
      if @statements
        @statements.set_prev(env) 
        @statements.increment_indentation
      end
    end

    def block_statement?
      true
    end

    def increment_indentation
      #puts "#{@name} is indenting to #{env.indentation + 2}"
      env.indentation += 2
      [statements].flatten.compact.each{ |t| t.increment_indentation }      
      true
    end

    def to_ruby
      Array.new.tap do |arr|
        arr << space("def #{as_ruby(@name)}", env)
        arr << as_ruby(statements) if statements
        arr << space("end", env)
      end.join("\n")
    end
  end

  class Block < Node
    def initialize(statements=nil)
      @statements = statements
      super()
      if @statements
        @statements.set_prev(env) 
        @statements.increment_indentation
      end
    end

    def to_ruby
      puts @statements.inspect
      Array.new.tap do |arr|
        arr << space("-> do", env)
        arr << as_ruby(@statements) if @statements
        arr << space("end", env)
      end.join("\n")
    end

  end
  
end