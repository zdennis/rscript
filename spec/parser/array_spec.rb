require 'spec_helper'

describe "Parsing arrays" do
  subject { ast.to_ruby }
  let(:ast){ RScript::Parser.new.parse(code) }

  describe "empty array" do
    code <<-EOS.heredoc.chomp
      |[]
    EOS

    it { should eql <<-EOS.heredoc.chomp
        |[]
      EOS
    }
  end

  describe "array with a single value" do
    code <<-EOS.heredoc.chomp
      |[1]
      |[b]
      |[bar()]
    EOS

    it { should eql <<-EOS.heredoc.chomp
        |[1]
        |[b]
        |[bar()]
      EOS
    }
  end

end