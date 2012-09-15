require 'spec_helper'

describe "Parsing method definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "method definitions auto-assignment" do
    code <<-EOS.heredoc.chomp
      |def initialize(@a, @b)
      |
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |def initialize(a, b)
      |  @a = a
      |  @b = b
      |end
    EOS
  end
end
