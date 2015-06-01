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

  describe "parenthetical expressions" do
    code <<-EOS.heredoc.chomp
      |(a + b) * 5 - (7 / 3)
      |((a + b) * 5) - (7 / (3))
      |(3)
      |((4))
      |(((((((((((((5)))))))))))))
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |(a + b) * 5 - (7 / 3)
      |((a + b) * 5) - (7 / (3))
      |(3)
      |((4))
      |(((((((((((((5)))))))))))))
    EOS
  end

  describe "compound assignments" do
    code <<-EOS.heredoc.chomp
      |a += 5
      |b *= 6
      |c /= 7
      |d -= 11
      |@a += 5
      |@b *= 6
      |@c /= 7
      |@d -= 11
    EOS

    it_outputs_as <<-EOS.heredoc.chomp
      |a += 5
      |b *= 6
      |c /= 7
      |d -= 11
      |@a += 5
      |@b *= 6
      |@c /= 7
      |@d -= 11
    EOS
  end


end
