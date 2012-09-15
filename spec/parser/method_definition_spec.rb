require 'spec_helper'

describe "Parsing method definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "method definitions auto-assignment" do
    code <<-EOS.heredoc.chomp
      |def initialize(@a, @b)
      |
      |def foo(@a, b, @c, d)
      |
      |def foo(@a = 5, @b = 1 + 5 * (7 - 9))
      |
      |def foo(@a=5, @b=1+5*(7-9))
      |
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |def initialize(a, b)
      |  @a = a
      |  @b = b
      |end
      |
      |def foo(a, b, c, d)
      |  @a = a
      |  @c = c
      |end
      |
      |def foo(a = 5, b = 1 + 5 * (7 - 9))
      |  @a = a
      |  @b = b
      |end
      |
      |def foo(a = 5, b = 1 + 5 * (7 - 9))
      |  @a = a
      |  @b = b
      |end
    EOS
  end
end
