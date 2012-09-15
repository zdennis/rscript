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
    EOS
  end
end
