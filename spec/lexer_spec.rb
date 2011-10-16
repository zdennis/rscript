require 'spec_helper'

describe RScript::Lexer do
  subject { described_class.new(:infinite => 100).tokenize(code) }

  describe "single token on a single line" do
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
      <<-CODE.gsub(/ +\|/, '')
        |foo
        |bar baz
        |yaz
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
      <<-CODE.gsub(/ +\|/, '')
        |foo
        |
        |
        |bar
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
  
  describe "indentation" do
    context "single scope" do
      let(:code){
        <<-CODE.gsub(/ +\|/, '')
          |foo
          |  bar
          |  baz
        CODE
      }
      
      it { should eq [
        [:Identifier, "foo", 0, newLine: true],
        [:Terminator, "\n", 0],
        [:Indent, 2, 1],
        [:Identifier, "bar", 1, newLine: true],
        [:Terminator, "\n", 1],
        [:Identifier, "baz", 2, newLine: true],
        [:Terminator, "\n", 2],
        [:Outdent, 2, 3]
      ]}
    end

    context "multiple scopes in" do
      let(:code){
        <<-CODE.gsub(/ +\|/, '')
          |foo
          |  bar
          |    baz
        CODE
      }
      
      it { should eq [
        [:Identifier, "foo", 0, newLine: true],
        [:Terminator, "\n", 0],
        [:Indent, 2, 1],
        [:Identifier, "bar", 1, newLine: true],
        [:Terminator, "\n", 1],
        [:Indent, 2, 2],
        [:Identifier, "baz", 2, newLine: true],
        [:Terminator, "\n", 2],
        [:Outdent, 2, 3],
        [:Outdent, 2, 3],
      ]}
    end

    context "in/out multiple scopes" do
      let(:code){
        <<-CODE.gsub(/ +\|/, '')
          |aaa
          |  baa
          |
          |abb
          |  bbb
          |    caa
          |    cbb
          |  bcc
          |    ccc
          |acc
          |add
        CODE
      }
      
      it { should eq [
        [:Identifier, "aaa", 0, newLine: true],
        [:Terminator, "\n", 0],
        [:Indent, 2, 1],
        [:Identifier, "baa", 1, newLine: true],
        [:Terminator, "\n", 1],

        [:Outdent, 2, 3],
        [:Identifier, "abb", 3, newLine: true],
        [:Terminator, "\n", 3],
        [:Indent, 2, 4],
        [:Identifier, "bbb", 4, newLine: true],
        [:Terminator, "\n", 4],
        [:Indent, 2, 5],
        [:Identifier, "caa", 5, newLine: true],
        [:Terminator, "\n", 5],
        [:Identifier, "cbb", 6, newLine: true],
        [:Terminator, "\n", 6],

        [:Outdent, 2, 7],
        [:Identifier, "bcc", 7, newLine: true],
        [:Terminator, "\n", 7],
        [:Indent, 2, 8],
        [:Identifier, "ccc", 8, newLine: true],
        [:Terminator, "\n", 8],

        [:Outdent, 2, 9],
        [:Outdent, 2, 9],
        [:Identifier, "acc", 9, newLine: true],
        [:Terminator, "\n", 9],
        [:Identifier, "add", 10, newLine: true],
        [:Terminator, "\n", 10]
      ]}
    end
  end

  describe "operators" do
    describe "mathematical: + - * / %" do
      let(:code){ "1 + 2 - 3 * 4 / 5 % 6" }
    
      it { should eq [
        [:Number, "1", 0],
        [:Operator, "+", 0],
        [:Number, "2", 0],
        [:Operator, "-", 0],
        [:Number, "3", 0],
        [:Operator, "*", 0],
        [:Number, "4", 0],
        [:Operator, "/", 0],
        [:Number, "5", 0],
        [:Operator, "%", 0],
        [:Number, "6", 0]
      ]}
    end

    describe "mathematical to the power of: **" do
      context "no spaces" do
        let(:code){ "1**2" }
      
        it { should eq [
          [:Number, "1", 0],
          [:Operator, "**", 0],
          [:Number, "2", 0]
        ]}
      end
      
      context "with spaces" do
        let(:code){ "1 ** 2" }
      
        it { should eq [
          [:Number, "1", 0],
          [:Operator, "**", 0],
          [:Number, "2", 0]
        ]}
      end
    end

    describe "parentheses" do
      describe "empty parens: ()" do
        let(:code){ "()" }

        it { should eq [
          [:Operator, "(", 0],
          [:Operator, ")", 0]
        ]}
      end
      
      describe "nonempty parens: (...)" do
        let(:code){ "(1)" }

        it { should eq [
          [:Operator, "(", 0],
          [:Number, "1", 0],
          [:Operator, ")", 0]
        ]}
      end
    end

    describe "assignment" do
      describe "simple assignment" do
        context "with no spaces" do
          let(:code){ "a=1" }
          it { should eq [
            [:Identifier, "a", 0],
            [:Assign, "=", 0],
            [:Number, "1", 0]
          ]}
        end

        context "with spaces" do
          let(:code){ "a = 1" }
          it { should eq [
            [:Identifier, "a", 0],
            [:Assign, "=", 0],
            [:Number, "1", 0]
          ]}
        end
      end

      describe "compound assignment" do
        %w( += -= *= /= ).each do |operator|
          describe operator do
            context "with no spaces" do
              let(:code){ "a#{operator}1" }
              it { should eq [
                [:Identifier, "a", 0],
                [:CompoundAssign, operator, 0],
                [:Number, "1", 0]
              ]}
            end

            context "with spaces" do
              let(:code){ "a #{operator} 1" }
              it { should eq [
                [:Identifier, "a", 0],
                [:CompoundAssign, operator, 0],
                [:Number, "1", 0]
              ]}
            end
          end
        end
      end

    end
 
    describe "comparison" do
      %w( < <= == > >= != ).each do |operator|
        describe operator do
          context "with no spaces" do
            let(:code){ "a#{operator}1" }
            it { should eq [
              [:Identifier, "a", 0],
              [:Comparison, operator, 0],
              [:Number, "1", 0]
            ]}
          end

          context "with spaces" do
            let(:code){ "a #{operator} 1" }
            it { should eq [
              [:Identifier, "a", 0],
              [:Comparison, operator, 0],
              [:Number, "1", 0]
            ]}
          end
        end
      end
    end

    describe "logic" do
      %w( || && & | ^).each do |operator|
        describe operator do
          context "with no spaces" do
            let(:code){ "a#{operator}1" }
            it { should eq [
              [:Identifier, "a", 0],
              [:Logic, operator, 0],
              [:Number, "1", 0]
            ]}
          end

          context "with spaces" do
            let(:code){ "a #{operator} 1" }
            it { should eq [
              [:Identifier, "a", 0],
              [:Logic, operator, 0],
              [:Number, "1", 0]
            ]}
          end
        end
      end
    end

    describe "bit-shifting" do
      %w( << >> ).each do |operator|
        describe operator do
          context "with no spaces" do
            let(:code){ "a#{operator}1" }

            it { should eq [
              [:Identifier, "a", 0],
              [:Shift, operator, 0],
              [:Number, "1", 0]
            ]}
          end
          
          context "with spaces" do
            let(:code){ "a #{operator} 1" }
            
            it { should eq [
              [:Identifier, "a", 0],
              [:Shift, operator, 0],
              [:Number, "1", 0]
            ]}
          end
        end
      end
    end
    
  end

  describe "keywords" do
    describe "class" do
      let(:code){ "class" }
      
      it { should eq [
        [:Class, "class", 0]
      ]}
    end
  end
end

