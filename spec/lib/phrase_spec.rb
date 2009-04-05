require File.dirname(__FILE__) + '/../spec_helper'

module Semr
  describe Phrase do

    before :each do
      @concepts = {
        :word => Concept.new(:word, '(\w+)'),
        :other => Concept.new(:other, '(\w+)')
      }
      @phrase = Phrase.new @concepts, 'i might have <:other> :word'
    end

    it 'should handle phrases including optional concepts if they are absent' do
      @phrase.handles?("i might have luck").should be_true
    end

    it 'should handle phrases including optional concepts if they are present' do
      @phrase.handles?("i might have dumb luck").should be_true
    end

  end
end
