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
    def initialize(head, tail=nil)
      super()
      @head, @tail = head, tail
    end

    def set_prev(prev)
      [@head, @tail].flatten.compact.each{ |t| t.set_prev(prev) }
    end

    def increment_indentation
      [@head, @tail].flatten.compact.each{ |t| t.increment_indentation }
    end
    
    def to_ruby
      Array.new.tap do |arr|
        arr << as_ruby(@head)
        arr << "" if @head.block_statement?

        case @tail
        when nil # no-op
        when Node
          arr << as_ruby(@tail)
        else
          # assume we have a Lexer::Token
          arr << "" if @tail.tag == "\n"
        end
      end.join("\n")
    end
  end
  
  class Statement < Node
    def initialize(statement)
      super()
      @statement = statement
    end

    def block_statement?
      @statement.is_a?(ClassDefinition)
    end

    def increment_indentation
      if @statement
        @statement.increment_indentation
      else
        env.indentation += 2
      end
    end
    
    def to_ruby
      as_ruby(@statement)
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

    def increment_indentation
      puts "#{@name} indents to #{env.indentation + 2}"
      env.indentation += 2
      [statements].flatten.compact.each{ |t| t.increment_indentation }      
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
    def initialize(name, statements=nil)
      super()
      @name, @statements = name, statements
    end
    
    def to_ruby
      Array.new.tap do |arr|
        arr << space("def #{as_ruby(@name)}", env.prev)
        arr << space(@statements.to_ruby.chomp, env)
        arr << space("end", env.prev)
      end.join("\n")
    end
  end
  
end