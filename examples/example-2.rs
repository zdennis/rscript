module ConvertToArraySanitizer
  def self.sanitize(words)
    [words].flatten.compact

module StripUnallowedCharactersSanitizer
  def self.sanitize(words)
    words.map -> |str| 
      str.gsub(/[^\w\s\!\"]/, '')

module RemoveUnnecessaryWhitespaceSanitizer
  def self.sanitize(words)
    words.map -> |str| 
      str.gsub(/\s+/, ' ').strip

module ReverseWordsThatStartWithVowel
  def self.sanitize(words)
    words.map -> |str|
      str.split(/\s/) -> |nstr|
        nstr =~ /^[aeiou]/ ? nstr.reverse : nstr
      .join(" ") # this is an example of a method chain with the previous method call that took a block

class WordList
  attr_reader :words
  
  SANITIZERS = [
    ConvertToArraySanitizer,
    StripUnallowedCharactersSanitizer,
    RemoveUnnecessaryWhitespaceSanitizer,
    ReverseWordsThatStartWithVowel]
  
  def words=(words)
    @words = SANITIZERS.inject(words) -> |words, sanitizer|
      sanitizer.sanitize words
