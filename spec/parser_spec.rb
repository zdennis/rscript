require 'spec_helper'

describe RScript::Parser do
  def self.source(code)
    let(:source){ code.gsub /^\s+\|/, '' }
  end
  
  subject { ast.to_ruby }
  let(:ast){ self.described_class.new.parse(source) }
    
  describe "empty program" do
    source ""
    it { should eq "" }
  end
    
  describe "simple statements" do
    source <<-EOS
      |a
      |b
    EOS
    
    it { should eq <<-EOS.gsub(/^\s+\|/, '')
        |a
        |b
      EOS
    }
    
  end
  
  
end