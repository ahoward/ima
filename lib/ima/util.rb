module Ima
  module Util
    def present?(value)
      value.to_s.strip.size > 0
    end

    def blank?(value)
      !present?(value)
    end

    def count_tokens(text, code_threshold: 0.05)
      return 0 if text.nil? || text.strip.empty?

      code_symbols = '{}()[]<>;=+\-*/#:_\''.freeze

      text_length = text.length

      symbol_count = text.count(code_symbols)
      symbol_ratio = symbol_count / text_length.to_f

      #if symbol_ratio >= code_threshold
        #estimate_tokens_by_chars(text)
      #else
        #estimate_tokens_by_words(text)
      #end
      [estimate_tokens_by_chars(text), estimate_tokens_by_words(text)].max
    end

    def estimate_tokens_by_chars(text, chars_per_token: 3.0)
      return 0 if text.nil? || text.empty?
      (text.length / chars_per_token).ceil
    end

    def estimate_tokens_by_words(text, tokens_per_word: 1.5)
      return 0 if text.nil? || text.empty?
      words = text.split(/\s+/)
      (words.size * tokens_per_word).ceil
    end

    extend Util
  end
end
