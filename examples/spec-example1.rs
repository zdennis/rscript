require 'spec_helper'

describe WordList ->
  describe "#words=" ->
    it "handles nil as an empty array" ->
      subject.words = nil
      subject.words.should eq([])
    
    it "handles a string as a single-word array" ->
      subject.words = "hello there"
      subject.words.should eq(["hello there"])

    
    it "reduces consecutive spaces to a single space" ->
      subject.words = ["hello        world!"]
      subject.words.should eq(["hello world!"])
    end
    
    it "strips leading white-space" ->
      subject.words = [" \tHowdy"]
      subject.words.should eq(["Howdy"])
    
    it "strips trailing white-space" ->
      subject.words = ["Au revoir\t "]
      subject.words.should eq(["Au revoir"])

    it "reverses any word that starts with a vowel" ->
      subject.words = ["apples", "berries", "apricots and oranges please"]
      subject.words.should eq(["selppa", "berries", "stocirpa dna segnaro please"])

    
    it "strips non alpha-numeric characters except: _ \" !" ->
      "` ~ @ # $ % ^ & * ( ) - + = [ ] \ { } | ; ' : , . / < > ?".split(" ").each -> |ch|
        subject.words = ["this #{ch}", "certainly", "#{ch} does"]
        subject.words.should eq(["this", "certainly", "does"])
