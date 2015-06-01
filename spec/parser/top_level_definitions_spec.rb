require 'spec_helper'

describe "Parsing class definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "any statement can be followed by a comment" do
    code <<-EOS.heredoc.chomp
      |foo # comment1
      |
      |a = 5 # comment2
      |
      |b = a + 6 # comment3
      |
      |bar(1,2, c,d) # comment4
      |
      |def foo # comment5
      |
      |def bar(a, b) # comment6
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |foo # comment1
      |
      |a = 5 # comment2
      |
      |b = a + 6 # comment3
      |
      |bar(1, 2, c, d) # comment4
      |
      |def foo # comment5
      |end
      |
      |def bar(a, b) # comment6
      |end
      EOS
  end

  describe "top-level method calls" do
    code <<-EOS.heredoc
      |foo
      |bar
      |baz
      |a = 5
      |b = a + 6
      |bar 1
      |bar 1, 2, c, d
      |bar(1,2, c,d)
      |foo(a + b + c, 1 * 5, 8 / 4, 3 + (3 - d))
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |foo
      |bar
      |baz
      |a = 5
      |b = a + 6
      |bar 1
      |bar 1, 2, c, d
      |bar(1, 2, c, d)
      |foo(a + b + c, 1 * 5, 8 / 4, 3 + (3 - d))
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
