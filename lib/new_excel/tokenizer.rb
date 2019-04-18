module NewExcel
  class Tokenizer
    class << self
      def get_tokens(str)
        new(str).tokenize
      end

      alias_method :tokenize, :get_tokens
    end

    def initialize(str)
      str = str.strip
      @str = str
      @is_map = str =~ /^Map\!/
      @is_formula = str[0] == "="
      # thank you - https://martinfowler.com/bliki/HelloRacc.html
      @scanner = StringScanner.new(str)
      @q = []
    end

    attr_reader :scanner

    def tokenize
      @q = []

      until scanner.eos?
        if @is_map || @is_formula
          case
          when match = scanner.scan(/\"(\\.|[^"\\])*\"/)
            @q << [:QUOTED_STRING, match]
          # when match = scanner.scan(/Map\!/)
          #   @q << [:MAP, match]
          when match = scanner.scan(/Map\!/)
            @q << [:MAP, match]
          when comments = tokens_for_comments(scanner)
            # ignore comments for now
          when match = scanner.scan(/[a-zA-Z][a-zA-Z0-9\_\- ]+\:/)
            @q << [:KEY_WITH_COLON, match]
          when match = scanner.scan(/\=/)
            @q << [:EQ, match]
          when match = scanner.scan(/\,/)
            @q << [:COMMA, match]
          when match = scanner.scan(/\(/)
            @q << [:OPEN_PAREN, match]
          when match = scanner.scan(/\)/)
            @q << [:CLOSE_PAREN, match]
          when token_pair = tokens_for_primitive_match(scanner)
            @q << token_pair
          when match = scanner.scan(/[a-zA-Z][a-zA-Z0-9\_\-]*/)
            @q << [:ID, match]
          when match = scanner.scan(/\./)
            @q << [:DOT, match]
          # when match = scanner.scan(/\:/)
          #   @q << [:COLON, match]
          when scanner.scan(/\s+/)
            #ignore whitespace
          when token_pair = tokens_for_text_scan(scanner)
            @q << token_pair
          else
            raise "Unknown token!"
          end
        else
          case
          when comments = tokens_for_comments(scanner)
            # ignore comments for now
          when token_pair = tokens_for_primitive_match(scanner)
            @q << token_pair
          when token_pair = tokens_for_text_scan(scanner)
            @q << token_pair
          else
            raise "Unknown token: #{scanner.inspect}!"
          end
        end
      end

      @q.push [false, false]
      @q
    end

  private

    def tokens_for_primitive_match(scanner)
      case
      when match = scanner.scan(/\d+[-\/]\d+[-\/]\d+( \d+\:\d+(\:\d+)?)?/)
        [:DATE_TIME, match]
      when match = scanner.scan(/\d+\:\d+/)
        [:TIME, match]
      when match = scanner.scan(/\d+\.\d+/)
        [:FLOAT, match]
      when match = scanner.scan(/\-?\d+/)
        [:INTEGER, match]
      end
    end

    def tokens_for_text_scan(scanner)
      if match = scanner.scan(/(.+)\n?/)
        [:TEXT, match]
      end
    end

    def tokens_for_comments(scanner)
      if match = scanner.scan(/#.*/)
        [:COMMENT, match]
      end
    end
  end
end
