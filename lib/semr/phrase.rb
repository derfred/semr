module Semr
  class InvalidConceptError < RuntimeError; end;
  class Phrase
    attr_reader :regex, :block

    # ^ matches phrase from beginning, should we use $
    # regex = Regexp.new(phrase, Regexp::IGNORECASE) <- fall back when oniguruma not installed
    def initialize(all_concepts, phrase, &block)
      refined_phrase = remove_optional_words(phrase)
      @original = "^#{parameterise_concepts(refined_phrase, all_concepts)}"
      @regex, @block = Oniguruma::ORegexp.new(@original, :options => Oniguruma::OPTION_IGNORECASE), block      
    end

    def concepts
      @concepts ||= []
    end

    def remove_optional_words(phrase)
      phrase.gsub(/\<([\w]*)\>\s?/, '(\1)?\s?')
    end

    def parameterise_concepts(phrase, all_concepts)
      phrase.symbols.each do |symbol|
        if all_concepts[symbol].nil?
          raise InvalidConceptError.new("Unable to create phrase because :#{symbol} concept has not been defined.")  
        else
          concept = all_concepts[symbol]
          concepts << concept

          optional_concept_matcher = "((?<#{symbol}>#{concept.definition.to_regexp})\\s)?"
          phrase.gsub!(/\<:#{symbol}\>\s?/, optional_concept_matcher)

          concept_matcher = "(?<#{symbol}>#{concept.definition.to_regexp})"
          phrase.gsub!(":#{symbol}", concept_matcher)
        end
      end
      phrase
    end

    def handles?(statement)
      match = regex.match(statement)
      !match.nil?
    end

    def interpret(statement, translation)
      args = []
      regex.scan(statement) do |match|
        @concepts.each do |concept|
          actual_match = match[concept.name]
          args << concept.normalize(actual_match)
        end
      end
      # args = args.first if args.size == 1
      translation.instance_exec(*args, &block)
    end
    
    def debug(match)
      matches = match[0..match.end]
      matches.each do |match|
        puts match
        puts ' ---- '
      end
    end
    
    def to_regexp
      "(#{@original})"
    end
  end
end
# module Semr
#   class Phrase
#     attr_reader :regex, :block
# 
#     def initialize(phrase, &block)
#       @original = phrase
#       phrase = "^#{phrase}" #match phrase from beginning..$
#       #@regex, @block = Regexp.new(phrase, Regexp::IGNORECASE), block
#       @regex, @block = Oniguruma::ORegexp.new(phrase, :options => Oniguruma::OPTION_IGNORECASE), block      
#     end
# 
#     def handles?(statement)
#       match = statement.match(regex)
#       !match.nil?
#     end
# 
#     def interpret(statement, translation)
#       args = []
#       statement.scan(regex) do |match|        
#         match = match.flatten.first if match.flatten.size == 1
#         match.delete(nil) if match.kind_of?(Array)
#         args << match
#       end
#       # puts args.inspect
#       translation.instance_exec(*args.flatten, &block)
#     end
#   
#     def to_regexp
#       "(#{@original})"
#     end
#   end
# end