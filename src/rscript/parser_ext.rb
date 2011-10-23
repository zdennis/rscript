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
  end
  
  class Statements < Node
    def initialize(head, tail)
      super()
      @head, @tail = head, tail
    end
  end
  
  class Statement < Node
    def initialize(statement)
      super()
      @statement = statement
    end
  end
  
  class Expression < Node
    def initialize(head, op, tail)
      super()
      @head, @op, @tail = head, op, tail
    end
  end
  
  class Operator < Node
    def initialize(op)
      @op = op
    end
  end
  
end