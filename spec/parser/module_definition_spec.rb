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
        |
        |  def bar(a = self.foo)
        |  end
        |
        |  def bar(a = self.foo, b = self.baz, c = bar, d = bang)
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

  describe "instance variables" do
    describe "module-level" do
      code <<-EOS.heredoc
        |module Foo
        |  @bar = 5
        |  @foo
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |  @bar = 5
        |  @foo
        |end
      EOS
    end

    describe "instance-level" do
      code <<-EOS.heredoc
        |module Foo
        |  def initialize(a, b)
        |    @bar = a
        |    @foo = b
        |    @bar
        |    @foo
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |  def initialize(a, b)
        |    @bar = a
        |    @foo = b
        |    @bar
        |    @foo
        |  end
        |end
      EOS
    end
  end

  describe "module method definitions" do
    describe "and no method body" do
      code <<-EOS.heredoc
        |module Foo
        |  def self.bar
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |  def self.bar
        |  end
        |end
      EOS
    end

    describe "with simple body" do
      code <<-EOS.heredoc
        |module Foo
        |  def self.bar
        |    baz
        |    1 + 2.5 / 4 * 500
      EOS
    
      it_outputs_as <<-EOS.heredoc.chomp
        |module Foo
        |  def self.bar
        |    baz
        |    1 + 2.5 / 4 * 500
        |  end
        |end
      EOS
    end
  end

end  
