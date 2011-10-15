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
      [:Terminator, "\n",  0],
      [:Identifier, "bar", 1],
      [:Identifier, "baz", 1, newLine: true],
      [:Terminator, "\n",  1],
      [:Identifier, "yaz", 2, newLine: true],
      [:Terminator, "\n",  2]
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
      [:Terminator, "\n",  0],
      [:Identifier, "bar", 3, newLine: true],
      [:Terminator, "\n",  3],
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

  describe "multiline single quoted strings" do
    let(:code) { %|'foo\n  bar'| }
    
    it { should eq [
      [:String, "'foo\n  bar'", 0]
    ]}
  end

  describe "basic double quoted strings" do
    let(:code){ %|"foo" "bar" "baz \\" yaz"| }
    
    it { should eq [
      [:String, '"foo"', 0],
      [:String, '"bar"', 0],
      [:String, '"baz \\" yaz"', 0]
    ]}
  end

  describe "basic multiline double quoted strings" do
    let(:code) { %|"foo\n  bar"| }
    
    it { should eq [
      [:String, %|"foo\n  bar"|, 0]
    ]}
  end
  
  describe "comments" do
    context "line starting with comment" do
      let(:code){ "#foo" }
      
      it { should eq [
        [:Comment, "foo", 0]
      ]}
    end

    context "line ending with comment" do
      let(:code){ "foo # bar" }

      it { should eq [
        [:Identifier, "foo", 0],
        [:Comment, " bar", 0]
      ]}
    end
    
    context "multi line comment" do
      let(:code){ 
        <<-CODE.gsub(/ +\|/, '')
          |###
          |foo
          |bar
          |###
          |baz
        CODE
      }
      
      it { should eq [
        [:HereComment, "foo\nbar\n", 0],
        [:Terminator, "\n", 0],
        [:Identifier, "baz", 4, newLine: true],
        [:Terminator, "\n", 4]
      ]}
    end
    
  end


end

