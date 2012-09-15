require 'spec_helper'

describe "Parsing comments" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  code <<-EOS.heredoc.chomp
    |# single line comment
    |
    |###
    |multiline 
    |comment
    |here
    |###
    |
    |###
    |another 
    |multiline
    |comment
    |###
  EOS

  it_outputs_as <<-EOS.heredoc
    |# single line comment
    |
    |# multiline
    |# comment
    |# here
    |
    |# another
    |# multiline
    |# comment
  EOS
end
