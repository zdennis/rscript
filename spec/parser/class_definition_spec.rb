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
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |  def bar
        |  end
        |end
      EOS
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |class Foo
        |  def bar
        |    baz
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |class Foo
        |  def bar
        |    baz
        |  end
        |end
      EOS
    end
  end
end  
