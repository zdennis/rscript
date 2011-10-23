require 'spec_helper'

class String
  def heredoc
    gsub(/^\s+\|/, '')
  end
end

describe RScript::Parser do
  def self.code(code)
    let(:code){ code.heredoc }
  end
  
  subject { ast.to_ruby }
  let(:ast){ self.described_class.new.parse(code) }
    
  describe "empty program" do
    code ""
    it { should eq "" }
  end

  describe "simple statement on a single line" do
    code <<-EOS.heredoc
      |a
    EOS
    
    it { should eq <<-EOS.heredoc
        |a
      EOS
    }
  end
    
  describe "simple statements across multiple lines" do
    code <<-EOS.heredoc
      |a
      |b
      |C
    EOS
    
    it { should eq <<-EOS.heredoc
        |a
        |b
        |C
      EOS
    }
  end
  
  describe "simple expression on a single line" do
    code <<-EOS.heredoc
      |a + b
    EOS
    
    it { should eq <<-EOS.heredoc
        |a + b
      EOS
    }
  end

  describe "mathematical operators in a single expression on a single line" do
    code <<-EOS.heredoc
      |a + b - c * d / e % f ** g
    EOS
    
    it { should eq <<-EOS.heredoc
        |a + b - c * d / e % f ** g
      EOS
    }
  end
  
  
end