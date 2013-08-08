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
      str = case token
            when Node
              token.to_ruby(self, options)
            when ::RScript::Lexer::Token
              token.tag              
            when String
              token
            when nil
              ""
            else
              raise NotImplementedError, "Do not know how to convert #{token.inspect} to ruby"        
            end
      str.sub!(/^(\s*)@/, '\1') if options[:omit_ivar_symbol]
      str
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

    def indent(&block)
      @env.indentation += 2
      yield
      @env.indentation -= 2
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
      @statements.to_ruby(self).chomp
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
      str = Array.new.tap do |arr|
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
      end.join "\n"
      str
    end
  end

  class Rvalue < Node
    def initialize(token)
      super()
      @token = token
    end

    def to_ruby(caller, options={})
      as_ruby(@token, :omit_ivar_symbol => options[:omit_ivar_symbol])
    end

    def identifier
      @token.tag
    end
  end

  class Statement < Node
    attr_reader :statement

    def initialize(statement, comment=nil)
      super()
      @comment = comment
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
      str = if @statement.is_a?(Rvalue) || @statement.is_a?(Expression)
        space(@statement.to_ruby(self, :omit_ivar_symbol => options[:omit_ivar_symbol]), env)
      else
        as_ruby(@statement)
      end
      str.sub(/\n+$/, "\n")
    end
  end

  class Assignment < Statement
    def lvalue
      @statement.lvalue
    end
  end
  
  class Expression < Node
    def initialize(head, op, tail)
      super()
      @head, @op, @tail = head, op, tail
    end

    def lvalue
      return @head if @head.is_a?(Rvalue)
    end

    def to_ruby(caller, options={})
      Array.new.tap do |arr|
        arr << as_ruby(@head, :omit_ivar_symbol => options[:omit_ivar_symbol])
        arr << @op.to_ruby(self) if @op
        arr << as_ruby(@tail)
      end.join(" ")
    end
  end

  class MethodCall < Expression
    def to_ruby(caller, options={})
      Array.new.tap do |arr|
        arr << as_ruby(@head)
        if @op
          arr << @op.to_ruby(self)
        elsif !@tail.is_a?(ParentheticalExpression)
          # only put a space if we're not dealing with parenthesis', 
          # ie: foo 1, 2, 3 otherwise don't space, ie: foo(1, 2, 3)
          arr << " "
        end
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
        arr.last.chomp! if statements && statements.tail.is_a?(MethodDefinition)
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

    def initialize(name_parts, statements=nil, parameter_list=nil, comment=nil)
      @name_parts = [name_parts].flatten
      @statements = statements
      @parameter_list = parameter_list
      @comment = comment
      super()
      if @statements
        @statements.set_prev(env) 
        @statements.increment_indentation
      end
    end

    def block_statement?
      @statements
    end

    def increment_indentation
      #puts "#{@name} is indenting to #{env.indentation + 2}"
      env.indentation += 2
      [statements].flatten.compact.each{ |t| t.increment_indentation }      
      true
    end

    def to_ruby(caller, options={})
      name = @name_parts.map{ |n| as_ruby(n) }.join(".")

      expansions = {}
      if @parameter_list
        @parameter_list.items.each do |item|
          if item.is_a?(Rvalue) && item.identifier =~ /^(@(.*))$/
            expansions[$1] = "#{$2}"
          elsif item.is_a?(Assignment) && item.lvalue.identifier =~ /^(@(.*))$/
            expansions[$1] = "#{$2}"
          end
        end
        name << "#{@parameter_list.to_ruby(self)}"
      end
      
     Array.new.tap do |arr|
        arr << space("def #{name}", env)
        arr.last << " #{@comment.to_ruby(self, supressNewLine: true)}" if @comment

        expansions.each_pair do |ivar, param|
          indent do
            arr << space("#{ivar} = #{param}", env)
          end
        end
        arr << as_ruby(statements) if statements
        arr << space("end", env)
        arr << "" if (@comment && @comment.newline?) || block_statement?
      end.join("\n")
    end
  end

  class List < Node
    attr_reader :items

    def initialize(*items)
      super()
      @items = items.flatten
    end

    def to_ruby(caller, options={})
      @items.map{ |item| item.to_ruby(self) }.join(", ")
    end
  end

  class ParameterList < List
    def self.from_list(list)
      if list.is_a?(List)
        items = []

        # a List usually contains a head and tail, so 
        # simulate recursively flattening this list through
        # iteration
        while list.is_a?(List)
          items.concat([list.items.first])
          if list.items[1].is_a?(List)
            list = list.items[1]
          elsif list.items[1]
            items << list.items[1]
            list = nil
          else
            list = nil
          end
        end
        new(items)
      else
        new(list)
      end
    end

    def to_ruby(caller, options={})
      [].tap do |arr|
        arr << "("
        arr << @items.map { |param| "#{param.to_ruby(self, :omit_ivar_symbol => true)}" }.join(", ")
        arr << ")"
      end.join
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

  class Comment < Node
    def initialize(comment)
      super()
      @comment = comment
    end

    def newline?
      @comment.attrs[:newLine]
    end

    def to_ruby(caller, options={})
      "##{as_ruby(@comment)}".tap do |str|
        str << "\n" if newline? && !options[:supressNewLine]
      end
    end
  end

  class HereComment < Comment
    def to_ruby(caller, options={})
      str = Array.new.tap do |arr|
        @comment.tag.each_line do |line|
          arr << "# #{as_ruby(line.strip)}"
        end
      end.join("\n")
      str << "\n" if @comment.attrs[:newLine]
      str
    end    
  end
  
end