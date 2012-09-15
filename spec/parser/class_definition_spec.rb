require 'spec_helper'

describe "Parsing class definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "one-line class definition with no body" do
    describe "and no trailing newline" do
      code <<-EOS.heredoc.chomp
        |class Foo
      EOS

      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |end
      EOS
    end

    describe "and a trailing newline" do
      code <<-EOS.heredoc
        |class Foo
      EOS
      
      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |end
      EOS
    end
  end

  describe "nested class definition" do
    code <<-EOS.heredoc
      |class Foo
      |  class Bar
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |class Foo
      |  class Bar
      |  end
      |end
    EOS
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

    it_outputs_as <<-EOS.heredoc.chomp
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

    it_outputs_as <<-EOS.heredoc.chomp
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
  end

  describe "class-level method call" do
    code <<-EOS.heredoc
      |class Foo
      |  bar
    EOS
  
    it_outputs_as <<-EOS.heredoc.chomp
      |class Foo
      |  bar
      |end
    EOS
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
        |  def bar(a = (5 + 1) * 5, b = 7 + foo)
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
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
        |end
      EOS
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |class Foo
        |  def bar
        |    baz
        |    1 + 2.5 / 4 * 500
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |  def bar
        |    baz
        |    1 + 2.5 / 4 * 500
        |  end
        |end
      EOS
    end
  end

  describe "class method definitions" do
    describe "and no method body" do
      code <<-EOS.heredoc
        |class Foo
        |  def self.bar
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |  def self.bar
        |  end
        |end
      EOS
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |class Foo
        |  def self.bar
        |    baz
        |    1 + 2.5 / 4 * 500
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |  def self.bar
        |    baz
        |    1 + 2.5 / 4 * 500
        |  end
        |end
      EOS
    end
  end

end  
