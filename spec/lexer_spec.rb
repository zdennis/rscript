require 'spec_helper'

describe RScript::Lexer do
  subject { described_class.new(:infinite => 100).tokenize(code) }

  describe "single identifier on a single line" do
    let(:code) { "foo" }
    
    it { should eq [[:Identifier, "foo", 0]] }
  end
  
  describe "multiple tokens on a single line" do
    let(:code) { "foo bar baz" }
    
    it { should eq [
      [:Identifier, "foo", 0],
      [:Identifier, "bar", 0],
      [:Identifier, "baz", 0]
    ]}
  end

  describe "multiple spaces are consumed between tokens" do
    let(:code) { "foo      bar     baz" }
    
    it { should eq [
      [:Identifier, "foo", 0],
      [:Identifier, "bar", 0],
      [:Identifier, "baz", 0]
    ]}
  end

  
  describe "multiple tokens on multiple lines" do
    let(:code) {
      <<-CODE
        foo
        bar baz
        yaz
      CODE
    }
    
    it { should eq [
      [:Identifier, "foo", 0, newLine: true],
      [:Terminator, "\n",  1],
      [:Identifier, "bar", 1],
      [:Identifier, "baz", 1, newLine: true],
      [:Terminator, "\n",  2],
      [:Identifier, "yaz", 2, newLine: true],
      [:Terminator, "\n",  3]
    ]}
  end
  
  describe "multiple new lines are consumed" do
    let(:code) {
      <<-CODE
        foo
        
        
        bar
      CODE
    }
    
    it { should eq [
      [:Identifier, "foo", 0, newLine: true],
      [:Terminator, "\n",  3],
      [:Identifier, "bar", 3, newLine: true],
      [:Terminator, "\n",  4],
    ]}
  end
  
  describe "whole, decimal, and exponential numbers" do
    let(:code){ "1 2.58 9e11" }
    
    it { should eq [
      [:Number, "1", 0],
      [:Number, "2.58", 0],
      [:Number, "9e11", 0]
    ]}
  end
  
  describe "single quoted strings" do
    let(:code){ %|'foo' 'bar' 'baz \\' yaz'| }
    
    it { should eq [
      [:String, "'foo'", 0],
      [:String, "'bar'", 0],
      [:String, "'baz \\' yaz'", 0]
    ]}
  end

end

