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
    
    def as_ruby(token, options={})
      return token.to_ruby(self, options) if Node === token
      return token.tag if ::RScript::Lexer::Token === token
      return nil if token.nil?
      raise NotImplementedError, "Do not know how to convert #{token.inspect} to ruby"
    end
    
    def to_ruby(caller, options={})
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

    def to_ruby(caller=nil)
      @statements.to_ruby(self)
    end
  end
  
  class Nothing < Node
    def to_ruby(caller=nil)
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
    
    def to_ruby(caller, options={})
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

    def to_ruby(caller, options={})
      as_ruby(@token)
    end
  end

  class Statement < Node
    attr_reader :statement

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
    
    def to_ruby(caller, options={})
      if @statement.is_a?(Rvalue) || @statement.is_a?(Expression)
        space(@statement.to_ruby(self), env)
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

    def to_ruby(caller, options={})      
      Array.new.tap do |arr|
        arr << as_ruby(@head)
        arr << @op.to_ruby(self)
        arr << as_ruby(@tail)
      end.join(" ")
    end
  end

  class MethodCall < Expression
    def to_ruby(caller, options={})      
      Array.new.tap do |arr|
        arr << as_ruby(@head)
        arr << @op.to_ruby(self)
        arr << as_ruby(@tail)
      end.join
    end

  end

  class ParentheticalExpression < Node
    def initialize(*expressions)
      super()
      @expressions = expressions.flatten
    end

    def to_ruby(caller, options={})
      [].tap do |arr|
        arr << "("
        arr << @expressions.map { |expr| "#{expr.to_ruby(self)}" }.join(",")
        arr << ")"
      end.join
    end
  end  
  
  class Operator < Node
    def initialize(op)
      @op = op
    end
    
    def to_ruby(caller, options={})
      # assume we have a Lexer::Token
      @op.tag
    end
  end
  
  class LogicOp < Operator
  end
  
  class ClassDefinition < Node
    attr_accessor :statements
    
    def initialize(name_parts, statements=nil)
      @name_parts = [name_parts].flatten
      @statements = statements
      @identifier = "class"      
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
    
    def to_ruby(caller, options={})
      name = @name_parts.flatten.map{ |node| as_ruby(node) }.join("::")
      results = Array.new.tap do |arr|
        arr << space("#{@identifier} #{name}", env)
        arr << as_ruby(statements) if statements
        arr << space("end", env)
      end.compact.join("\n")
      results
    end    
  end

  class ModuleDefinition < ClassDefinition
    def initialize(*)
      super
      @identifier = "module"
    end
  end
  
  class MethodDefinition < Node
    attr_reader :statements

    def initialize(name_parts, statements=nil, parameter_list=nil)
      @name_parts = [name_parts].flatten
      @statements = statements
      @parameter_list = parameter_list
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

    def to_ruby(caller, options={})
      name = @name_parts.map{ |n| as_ruby(n) }.join(".")
      name << "#{@parameter_list.to_ruby(self)}" if @parameter_list
      Array.new.tap do |arr|
        arr << space("def #{name}", env)
        arr << as_ruby(statements) if statements
        arr << space("end", env)
      end.join("\n")
    end
  end

  class List < Node
    def initialize(*items)
      super()
      @items = items
    end

    def to_ruby(caller, options={})
      @items.map{ |item| item.to_ruby(self) }.join(", ")
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

    def to_ruby(caller, options={ :supress => false })
      Array.new.tap do |arr|
        arr << space("-> do", env) unless options[:supress]
        arr << as_ruby(@statements) if @statements
        arr << space("end", env) unless options[:supress]
      end.join("\n")
    end
  end

  class ExpressionWithBlock < Node
    def initialize(expr, block)
      @expr, @block = expr, block
    end

    def to_ruby(caller, options)
      Array.new.tap do |arr|
        arr << space("#{@expr.to_ruby(self)} do", env)
        arr << as_ruby(@block, :supress => true) if @block
        arr << space("end", env)
      end.join("\n")
    end
  end

  
end