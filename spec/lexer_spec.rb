require 'spec_helper'

describe RScript::Lexer do
  subject { described_class.new(:infinite => 100).tokenize(code) }
  
  def t(val, lineno, attrs={})
    RScript::Lexer::Token.new(val, lineno, attrs)
  end
  
  describe "empty string" do
    let(:code) { "" }
    it { should eq [] }
  end

  describe "identifiers" do
    describe "naming: starts with lower-case alpha" do
      let(:code) { "a boo" }
      it { should eq [
        [:Identifier, t("a",   0)],
        [:Identifier, t("boo", 0)]
      ]}
    end

    describe "naming: starts with upper-case alpha" do
      let(:code) { "A Boo" }
      it { should eq [
        [:Identifier, t("A",   0)],
        [:Identifier, t("Boo", 0)]
      ]}
    end

    describe "naming: combines lower/upper-case alpha" do
      let(:code) { "AbbA FooBar" }
      it { should eq [
        [:Identifier, t("AbbA",   0)],
        [:Identifier, t("FooBar", 0)]
      ]}
    end

    describe "naming: cannot start with a number" do
      let(:code) { "9a" }
      it { should eq [
        [:Number, t("9",     0)],
        [:Identifier, t("a", 0)]
      ]}
    end

    describe "naming: can include numbrers" do
      let(:code) { "a9b ab9" }
      it { should eq [
        [:Identifier, t("a9b", 0)],
        [:Identifier, t("ab9", 0)]
      ]}
    end

    describe "naming: can start, include, and end with _" do
      let(:code) { "_a a_9 a9_ a_b_c" }
      it { should eq [
        [:Identifier, t("_a",    0)],
        [:Identifier, t("a_9",   0)],
        [:Identifier, t("a9_",   0)],
        [:Identifier, t("a_b_c", 0)]
      ]}
    end
    
    describe "single token on a single line" do
      let(:code) { "foo" }
    
      it { should eq [[:Identifier, t("foo", 0)]] }
    end
  
    describe "multiple tokens on a single line" do
      let(:code) { "foo bar baz" }
    
      it { should eq [
        [:Identifier, t("foo", 0)],
        [:Identifier, t("bar", 0)],
        [:Identifier, t("baz", 0)]
      ]}
    end

    describe "multiple spaces are consumed between tokens" do
      let(:code) { "foo      bar     baz" }
    
      it { should eq [
        [:Identifier, t("foo", 0)],
        [:Identifier, t("bar", 0)],
        [:Identifier, t("baz", 0)]
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
        [:Identifier, t("foo", 0, newLine: true)],
        [:Terminator, t("\n",  0)],
        [:Identifier, t("bar", 1)],
        [:Identifier, t("baz", 1, newLine: true)],
        [:Terminator, t("\n",  1)],
        [:Identifier, t("yaz", 2, newLine: true)],
        [:Terminator, t("\n",  2)]
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
        [:Identifier, t("foo", 0, newLine: true)],
        [:Terminator, t("\n",  0)],
        [:Identifier, t("bar", 3, newLine: true)],
        [:Terminator, t("\n",  3)],
      ]}
    end
  end

  describe "whole, decimal, and exponential numbers" do
    let(:code){ "1 2.58 9e11" }
    
    it { should eq [
      [:Number, t("1", 0)],
      [:Number, t("2.58", 0)],
      [:Number, t("9e11", 0)]
    ]}
  end
  
  describe "single quoted strings" do
    let(:code){ %|'foo' 'bar' 'baz \\' yaz'| }
    
    it { should eq [
      [:String, t("'foo'", 0)],
      [:String, t("'bar'", 0)],
      [:String, t("'baz \\' yaz'", 0)]
    ]}
  end

  describe "multiline single quoted strings" do
    let(:code) { %|'foo\n  bar'| }
    
    it { should eq [
      [:String, t("'foo\n  bar'", 0)]
    ]}
  end

  describe "basic double quoted strings" do
    let(:code){ %|"foo" "bar" "baz \\" yaz"| }
    
    it { should eq [
      [:String, t('"foo"', 0)],
      [:String, t('"bar"', 0)],
      [:String, t('"baz \\" yaz"', 0)]
    ]}
  end

  describe "basic multiline double quoted strings" do
    let(:code) { %|"foo\n  bar"| }
    
    it { should eq [
      [:String, t(%|"foo\n  bar"|, 0)]
    ]}
  end
  
  describe "comments" do
    context "line starting with comment" do
      let(:code){ "#foo" }
      
      it { should eq [
        [:Comment, t("foo", 0)]
      ]}
    end

    context "line ending with comment" do
      let(:code){ "foo # bar" }

      it { should eq [
        [:Identifier, t("foo", 0)],
        [:Comment, t(" bar", 0)]
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
        [:HereComment, t("foo\nbar\n", 0)],
        [:Terminator, t("\n", 0)],
        [:Identifier, t("baz", 4, newLine: true)],
        [:Terminator, t("\n", 4)]
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
        [:Identifier, t("foo", 0, newLine: true)],
        [:Terminator, t("\n", 0)],
        [:Indent, t(2, 1)],
        [:Identifier, t("bar", 1, newLine: true)],
        [:Terminator, t("\n", 1)],
        [:Identifier, t("baz", 2, newLine: true)],
        [:Terminator, t("\n", 2)],
        [:Outdent, t(2, 3)]
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
        [:Identifier, t("foo", 0, newLine: true)],
        [:Terminator, t("\n", 0)],
        [:Indent, t(2, 1)],
        [:Identifier, t("bar", 1, newLine: true)],
        [:Terminator, t("\n", 1)],
        [:Indent, t(2, 2)],
        [:Identifier, t("baz", 2, newLine: true)],
        [:Terminator, t("\n", 2)],
        [:Outdent, t(2, 3)],
        [:Outdent, t(2, 3)],
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
        [:Identifier, t("aaa", 0, newLine: true)],
        [:Terminator, t("\n", 0)],
        [:Indent, t(2, 1)],
        [:Identifier, t("baa", 1, newLine: true)],
        [:Terminator, t("\n", 1)],

        [:Outdent, t(2, 3)],
        [:Identifier, t("abb", 3, newLine: true)],
        [:Terminator, t("\n", 3)],
        [:Indent, t(2, 4)],
        [:Identifier, t("bbb", 4, newLine: true)],
        [:Terminator, t("\n", 4)],
        [:Indent, t(2, 5)],
        [:Identifier, t("caa", 5, newLine: true)],
        [:Terminator, t("\n", 5)],
        [:Identifier, t("cbb", 6, newLine: true)],
        [:Terminator, t("\n", 6)],

        [:Outdent, t(2, 7)],
        [:Identifier, t("bcc", 7, newLine: true)],
        [:Terminator, t("\n", 7)],
        [:Indent, t(2, 8)],
        [:Identifier, t("ccc", 8, newLine: true)],
        [:Terminator, t("\n", 8)],

        [:Outdent, t(2, 9)],
        [:Outdent, t(2, 9)],
        [:Identifier, t("acc", 9, newLine: true)],
        [:Terminator, t("\n", 9)],
        [:Identifier, t("add", 10, newLine: true)],
        [:Terminator, t("\n", 10)]
      ]}
    end
  end

  describe "operators" do
    describe "mathematical: + - * / %" do
      let(:code){ "1 + 2 - 3 * 4 / 5 % 6" }
    
      it { should eq [
        [:Number, t("1", 0)],
        ["+", t("+", 0)],
        [:Number, t("2", 0)],
        ["-", t("-", 0)],
        [:Number, t("3", 0)],
        ["*", t("*", 0)],
        [:Number, t("4", 0)],
        ["/", t("/", 0)],
        [:Number, t("5", 0)],
        ["%", t("%", 0)],
        [:Number, t("6", 0)]
      ]}
    end

    describe "mathematical to the power of: **" do
      context "no spaces" do
        let(:code){ "1**2" }
      
        it { should eq [
          [:Number, t("1", 0)],
          ["**", t("**", 0)],
          [:Number, t("2", 0)]
        ]}
      end
      
      context "with spaces" do
        let(:code){ "1 ** 2" }
      
        it { should eq [
          [:Number, t("1", 0)],
          ["**", t("**", 0)],
          [:Number, t("2", 0)]
        ]}
      end
    end

    describe "pairs" do
      [["(", ")"], ["[", "]"]].each do |pair|
        describe "empty pair: #{pair.join}" do
          let(:code){ pair.join }

          it { should eq [
            [pair.first, t(pair.first, 0)],
            [pair.last, t(pair.last, 0)]
          ]}
        end
      
        describe "nonempty pair: #{pair.join('...')}" do
          let(:code){ pair.join("1") }

          it { should eq [
            [pair.first, t(pair.first, 0)],
            [:Number, t("1", 0)],
            [pair.last, t(pair.last, 0)]
          ]}
        end
      end
    end

    describe "assignment" do
      describe "simple assignment" do
        context "with no spaces" do
          let(:code){ "a=1" }
          it { should eq [
            [:Identifier, t("a", 0)],
            [:Assign, t("=", 0)],
            [:Number, t("1", 0)]
          ]}
        end

        context "with spaces" do
          let(:code){ "a = 1" }
          it { should eq [
            [:Identifier, t("a", 0)],
            [:Assign, t("=", 0)],
            [:Number, t("1", 0)]
          ]}
        end
      end

      describe "compound assignment" do
        %w( += -= *= /= ).each do |operator|
          describe operator do
            context "with no spaces" do
              let(:code){ "a#{operator}1" }
              it { should eq [
                [:Identifier, t("a", 0)],
                [:CompoundAssign, t(operator, 0)],
                [:Number, t("1", 0)]
              ]}
            end

            context "with spaces" do
              let(:code){ "a #{operator} 1" }
              it { should eq [
                [:Identifier, t("a", 0)],
                [:CompoundAssign, t(operator, 0)],
                [:Number, t("1", 0)]
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
              [:Identifier, t("a", 0)],
              [:Comparison, t(operator, 0)],
              [:Number, t("1", 0)]
            ]}
          end

          context "with spaces" do
            let(:code){ "a #{operator} 1" }
            it { should eq [
              [:Identifier, t("a", 0)],
              [:Comparison, t(operator, 0)],
              [:Number, t("1", 0)]
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
              [:Identifier, t("a", 0)],
              [operator, t(operator, 0)],
              [:Number, t("1", 0)]
            ]}
          end

          context "with spaces" do
            let(:code){ "a #{operator} 1" }
            it { should eq [
              [:Identifier, t("a", 0)],
              [operator, t(operator, 0)],
              [:Number, t("1", 0)]
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
              [:Identifier, t("a", 0)],
              [:Shift, t(operator, 0)],
              [:Number, t("1", 0)]
            ]}
          end
          
          context "with spaces" do
            let(:code){ "a #{operator} 1" }
            
            it { should eq [
              [:Identifier, t("a", 0)],
              [:Shift, t(operator, 0)],
              [:Number, t("1", 0)]
            ]}
          end
        end
      end
    end
    
    describe "unary" do
      %w( - + ! ).each do |operator|
        describe operator do
          context "immediately before identifier" do
            let(:code){ "#{operator}a" }

            it { should eq [
              [:Unary, t(operator, 0)],
              [:Identifier, t("a", 0)]
            ]}
          end
        end
      end
    end
  end

  describe "keywords" do
    describe "class" do
      let(:code){ "class Foo" }
      
      it { should eq [
        [:Class, t("class", 0)],
        [:Identifier, t("Foo", 0)]
      ]}
    end

    describe "def" do
      let(:code){ "def foo" }
      
      it { should eq [
        [:Method, t("def", 0)],
        [:Identifier, t("foo", 0)]
      ]}
    end
    
    describe "conditionals" do
      %w( if unless else ).each do |keyword|
        describe keyword do
          let(:code){ keyword }
        
          it { should eq [
            [:Conditional, t(keyword, 0)]
          ]}
        end
      end
    end
    
    describe "lambda: ->" do
      context "anonymous block" do
        let(:code){ "->" }
      
        it { should eq [
          [:Lambda, t("->", 0)]
        ]}
      end

      context "after identifier" do
        let(:code){ "foo ->" }
      
        it { should eq [
          [:Identifier, t("foo", 0)],
          [:Lambda, t("->", 0)]
        ]}
      end


    end
  end
  
  describe "module ::" do
    let(:code){ "Foo::Bar" }

    it { should eq [
      [:Identifier, t("Foo", 0)],
      [:ModuleSeparator, t("::", 0)],
      [:Identifier, t("Bar", 0)]
    ]}

  end

end

