require 'spec_helper'

describe "Parsing module definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "one-line module definition with no body" do
    describe "and no trailing newline" do
      code <<-EOS.heredoc.chomp
        |module Foo
      EOS

      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |end
      EOS
    end

    describe "and a trailing newline" do
      code <<-EOS.heredoc
        |module Foo
      EOS
      
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |end
      EOS
    end
  end

  describe "nested module definition" do
    code <<-EOS.heredoc
      |module Foo
      |  module Bar
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |module Foo
      |  module Bar
      |  end
      |end
    EOS
  end

  describe "multiple nested module definitions" do
    code <<-EOS.heredoc
      |module Foo
      |  module Bar
      |  module Cat
      |
      |module Fab
      |  module Balloon
      |    module Cat
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |module Foo
      |  module Bar
      |  end
      |
      |  module Cat
      |  end
      |end
      |
      |module Fab
      |  module Balloon
      |    module Cat
      |    end
      |  end
      |end
    EOS
  end

  describe "nested module definitions with ::" do
    code <<-EOS.heredoc
      |module Foo::Bar
      |
      |module Foo::Bar::Baz::Bang
      |  bar
      |
      |module Foo
      |  module Bar::Baz::Bang
      |    bar
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |module Foo::Bar
      |end
      |
      |module Foo::Bar::Baz::Bang
      |  bar
      |end
      |
      |module Foo
      |  module Bar::Baz::Bang
      |    bar
      |  end
      |end
    EOS
  end

  describe "module-level method call" do
    code <<-EOS.heredoc
      |module Foo
      |  bar
    EOS
  
    it_outputs_as <<-EOS.heredoc.chomp
      |module Foo
      |  bar
      |end
    EOS
  end

  describe "instance method definitions" do
    describe "and no method body" do
      code <<-EOS.heredoc
        |module Foo
        |  def bar
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |  def bar
        |  end
        |end
      EOS
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |module Foo
        |  def bar
        |    baz
        |    1 + 2.5 / 4 * 500
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |  def bar
        |    baz
        |    1 + 2.5 / 4 * 500
        |  end
        |end
      EOS
    end
  end
end  
