module RScript::ParserExt
  def new_env
    @environment ||= Environment.new
  end
  
  def env
    @environment
  end
  
  class Environment
  end
  
  class Statements
    def initialize(head, tail)
      @head, @tail = head, tail
    end
  end
  
  class Statement
    def initialize(statement)
      @statement = statement
    end
  end
  
  class Item
    def initialize(val)
      @val = val
    end
    
    def to_s
      @val
    end
  end


  
end