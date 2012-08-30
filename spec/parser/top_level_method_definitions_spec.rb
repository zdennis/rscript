require 'spec_helper'

describe "Parsing class definitions" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "top-level method calls" do
    code <<-EOS.heredoc
      |foo
      |bar
      |baz
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |foo
      |bar
      |baz
    EOS
  end

  describe "top-level method definitions" do
    code <<-EOS.heredoc
      |def bar
      |
      |def baz
      |
      |def foo
      |def far
      |
    EOS
  
    it_outputs_as <<-EOS.heredoc.chomp
      |def bar
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
