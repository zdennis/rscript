require 'spec_helper'

describe "Parsing lambdas and blocks" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "lambda without assignment" do
    code <<-EOS.heredoc
      |-> 
      |  1 + 2 + 3
    EOS
  
    it_outputs_as <<-EOS.heredoc.chomp
      |-> do
      |  1 + 2 + 3
      |end
    EOS
  end

  describe "assigning a lambda" do
    code <<-EOS.heredoc
      |b = -> 
      |  1 + 2 + 3
    EOS
  
    it_outputs_as <<-EOS.heredoc.chomp
      |b = -> do
      |  1 + 2 + 3
      |end
    EOS
  end
end