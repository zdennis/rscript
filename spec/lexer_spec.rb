require 'spec_helper'

describe RScript::Lexer do
  subject { described_class.new.tokenize(code) }

  describe "Identifiers" do
    context "single token on a single line" do
      let(:code) { "foo" }
    
      it { should eq [[:Identifier, "foo", 0]] }
    end
    
    context "multiple tokens on a single line" do
      let(:code) { "foo bar baz" }
    
      it { should eq [
        [:Identifier, "foo", 0],
        [:Identifier, "bar", 0],
        [:Identifier, "baz", 0]
      ]}
    end
    
    context "multiple tokens on multiple lines" do
      let(:code) {
        <<-CODE
          foo
          bar baz
          yaz
        CODE
      }
      
      it { should eq [
        [:Identifier, "foo", 0],
        [:Terminator, "\n",  1],
        [:Identifier, "bar", 1],
        [:Identifier, "baz", 1],
        [:Terminator, "\n",  2],
        [:Identifier, "yaz", 2],
        [:Terminator, "\n",  3]
      ]}
    end
  end
  

end

