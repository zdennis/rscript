require 'spec_helper'

describe "Parsing class definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "top-level method calls" do
    code <<-EOS.heredoc
      |foo
      |bar
      |baz
      |a = 5
      |b = a + 6
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |foo
      |bar
      |baz
      |a = 5
      |b = a + 6
    EOS
  end

  describe "top-level method definitions" do
    code <<-EOS.heredoc
      |def bar
      |  a = 1
      |  b = 3.5
      |  c = a + b
      |
      |def baz
      |
      |def foo
      |def far
      |
    EOS
  
    it_outputs_as <<-EOS.heredoc.chomp
      |def bar
      |  a = 1
      |  b = 3.5
      |  c = a + b
      |end
      |
      |def baz
      |end
      |
      |def foo
      |end
      |
      |def far
      |end
    EOS
  end
end
