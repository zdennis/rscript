require 'spec_helper'

describe "Parsing class definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "one-line class definition with no body" do
    describe "and no trailing newline" do
      code <<-EOS.heredoc.chomp
        |class Foo
      EOS

      it { should eql <<-EOS.heredoc.chomp
          |class Foo
          |end
        EOS
      }
    end

    describe "and a trailing newline" do
      code <<-EOS.heredoc
        |class Foo
      EOS
      
      it { should eql <<-EOS.heredoc.chomp
        |class Foo
        |end
        EOS
      }
    end
  end

  describe "nested class definition" do
    code <<-EOS.heredoc
      |class Foo
      |  class Bar
    EOS

    it { should eql <<-EOS.heredoc.chomp
      |class Foo
      |  class Bar
      |  end
      |end
      EOS
      }
  end

  describe "multiple nested class definitions" do
    code <<-EOS.heredoc
      |class Foo
      |  class Bar
      |  class Cat
      |
      |class Fab
      |  class Balloon
      |    class Cat
    EOS

   it {
    should eq <<-EOS.heredoc.chomp
      |class Foo
      |  class Bar
      |  end
      |
      |  class Cat
      |  end
      |end
      |
      |class Fab
      |  class Balloon
      |    class Cat
      |    end
      |  end
      |end
      EOS
    }
  end

  describe "nested class definitions with ::" do
    code <<-EOS.heredoc
      |class Foo::Bar
      |
      |class Foo::Bar::Baz::Bang
      |  bar
      |
      |class Foo
      |  class Bar::Baz::Bang
      |    bar
    EOS

    it { should eql <<-EOS.heredoc.chomp
      |class Foo::Bar
      |end
      |
      |class Foo::Bar::Baz::Bang
      |  bar
      |end
      |
      |class Foo
      |  class Bar::Baz::Bang
      |    bar
      |  end
      |end
      EOS
      }
  end

  describe "class-level method call" do
    code <<-EOS.heredoc
      |class Foo
      |  bar
    EOS
  
    it { 
      should eql <<-EOS.heredoc.chomp
        |class Foo
        |  bar
        |end
      EOS
    }
  end

  describe "instance method definitions" do
    describe "and no method body" do
      code <<-EOS.heredoc
        |class Foo
        |  def bar
        |
        |  def baz(a)
        |
        |  def bar(a,b)
        |
        |  def bar(a, b, c, d, e, f)
        |
        |  def bar(a, b=5)
        |
        |  def bar(a = 5 + 1)
        |
        |  def bar(a = (5 + 1) * 5)
        |
        |  def bar(a = (5 + 1) * 5, b = 7 + foo)
        |
        |  def bar(a = self.foo)
        |
        |  def bar(a = self.foo, b = self.baz, c = bar, d = bang)
      EOS
    
      it { should eql <<-EOS.heredoc.chomp
        |class Foo
        |  def bar
        |  end
        |
        |  def baz(a)
        |  end
        |
        |  def bar(a, b)
        |  end
        |
        |  def bar(a, b, c, d, e, f)
        |  end
        |
        |  def bar(a, b = 5)
        |  end
        |
        |  def bar(a = 5 + 1)
        |  end
        |
        |  def bar(a = (5 + 1) * 5)
        |  end
        |
        |  def bar(a = (5 + 1) * 5, b = 7 + foo)
        |  end
        |
        |  def bar(a = self.foo)
        |  end
        |
        |  def bar(a = self.foo, b = self.baz, c = bar, d = bang)
        |  end
        |end
        EOS
      }
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |class Foo
        |  def bar
        |    baz
        |    1 + 2.5 / 4 * 500
      EOS
    
      it { should eql <<-EOS.heredoc.chomp
        |class Foo
        |  def bar
        |    baz
        |    1 + 2.5 / 4 * 500
        |  end
        |end
        EOS
      }
    end
  end

  describe "instance variables" do
    describe "class-level" do
      code <<-EOS.heredoc
        |class Foo
        |  @bar = 5
        |  @foo
      EOS
    
      it { should eql <<-EOS.heredoc.chomp
        |class Foo
        |  @bar = 5
        |  @foo
        |end
        EOS
      }
    end

    describe "instance-level" do
      code <<-EOS.heredoc
        |class Foo
        |  def initialize(a, b)
        |    @bar = a
        |    @foo = b
        |    @bar
        |    @foo
      EOS
    
      it { should eq <<-EOS.heredoc.chomp
          |class Foo
          |  def initialize(a, b)
          |    @bar = a
          |    @foo = b
          |    @bar
          |    @foo
          |  end
          |end
          EOS
       }
    end
  end

  describe "class method definitions" do
    describe "and no method body" do
      code <<-EOS.heredoc
        |class Foo
        |  def self.bar
      EOS
    
      it { should eql <<-EOS.heredoc.chomp
        |class Foo
        |  def self.bar
        |  end
        |end
        EOS
      }
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |class Foo
        |  def self.bar
        |    baz
        |    1 + 2.5 / 4 * 500
      EOS
    
      it { should eql <<-EOS.heredoc.chomp
        |class Foo
        |  def self.bar
        |    baz
        |    1 + 2.5 / 4 * 500
        |  end
        |end
        EOS
      }
    end
  end

end  
