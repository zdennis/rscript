require 'spec_helper'

class String
  def heredoc
    gsub(/^\s+\|/, '')
  end
end

describe RScript::Parser do
  def self.code(code)
    let(:code){ code.heredoc }
  end
  
  subject { ast.to_ruby }
  let(:ast){ self.described_class.new.parse(code) }
    
  describe "empty program" do
    code ""
    it { should eq "" }
  end

  describe "simple statement on a single line" do
    code <<-EOS.heredoc
      |a
    EOS
    
    it { should eq <<-EOS.heredoc
        |a
      EOS
    }
  end
    
  describe "simple statements across multiple lines" do
    code <<-EOS.heredoc
      |a
      |b
      |C
    EOS
    
    it { should eq <<-EOS.heredoc
        |a
        |b
        |C
      EOS
    }
  end
  
  describe "simple expression on a single line" do
    code <<-EOS.heredoc
      |a + b
    EOS
    
    it { should eq <<-EOS.heredoc
        |a + b
      EOS
    }
  end

  describe "mathematical operators in a single expression on a single line" do
    code <<-EOS.heredoc
      |a + b - c * d / e % f ** g
    EOS
    
    it { should eq <<-EOS.heredoc
        |a + b - c * d / e % f ** g
      EOS
    }
  end

  describe "logic operators in a single expression on a single line" do
    code <<-EOS.heredoc
      |a || b && c & d | e ^ f
    EOS
    
    it { should eq <<-EOS.heredoc
        |a || b && c & d | e ^ f
      EOS
    }
  end

  describe "top-level method definition" do
    code <<-EOS.heredoc
      |def foo
      |  bar
    EOS
  
    it { should eq <<-EOS.heredoc.chomp
        |def foo
        |  bar
        |end
      EOS
    }
  end

  describe "class definitions" do
    describe "class definition without body w/o no trailing newline" do
      code <<-EOS.heredoc.chomp
        |class Foo
      EOS
  
      it { should eq <<-EOS.heredoc.chomp
          |class Foo
          |end
        EOS
      }
    end

    describe "class definition without body w/trailing newline" do
      code <<-EOS.heredoc
        |class Foo
      EOS
      
      it { should eq <<-EOS.heredoc.chomp
          |class Foo
          |end
        EOS
      }
    end

    describe "class definition with nested class definition" do
      code <<-EOS.heredoc
        |class Foo
        |  class Bar
      EOS
  
      it { should eq <<-EOS.heredoc
          |class Foo
          |  class Bar
          |  end
          |end
        EOS
      }
    end

  end

  describe "top-level class definition" do
    code <<-EOS.heredoc
      |class Foo
      |  def bar
      |    baz
    EOS
  
    it { should eq <<-EOS.heredoc.chomp
        |class Foo
        |  def bar
        |    baz
        |  end
        |end
      EOS
    }
  end
end
