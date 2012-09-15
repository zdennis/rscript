require 'spec_helper'

describe RScript::Parser do  
  subject { ast.to_ruby }
  let(:ast){ self.described_class.new.parse(code) }
    
  describe "empty program" do
    code ""
    it_outputs_as ""
  end

  describe "simple statement on a single line" do
    code <<-EOS.heredoc.chomp
      |a
    EOS
    
    it_outputs_as <<-EOS.heredoc.chomp
      |a
    EOS
  end
    
  describe "simple statements across multiple lines" do
    code <<-EOS.heredoc.chomp
      |a
      |b
      |C
    EOS
    
    it_outputs_as <<-EOS.heredoc.chomp
      |a
      |b
      |C
    EOS
  end
  
  describe "simple expression on a single line" do
    code <<-EOS.heredoc.chomp
      |a + b
    EOS
    
    it_outputs_as <<-EOS.heredoc.chomp
      |a + b
    EOS
  end

  describe "mathematical operators in a single expression on a single line" do
    code <<-EOS.heredoc.chomp
      |a + b - c * d / e % f ** g
    EOS
    
    it_outputs_as <<-EOS.heredoc.chomp
      |a + b - c * d / e % f ** g
    EOS
  end

  describe "logic operators in a single expression on a single line" do
    code <<-EOS.heredoc.chomp
      |a || b && c & d | e ^ f
    EOS
    
    it_outputs_as <<-EOS.heredoc.chomp
      |a || b && c & d | e ^ f
    EOS
  end

end
