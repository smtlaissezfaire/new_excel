module NewExcel
  class Tokenizer
    def self.get_tokens(str)
      new(str).tokenize
    end

    def initialize(str)
      str = str.strip
      @str = str
      @is_formula = str[0] == "="
      # thank you - https://martinfowler.com/bliki/HelloRacc.html
      @scanner = StringScanner.new(str)
      @q = []
    end

    attr_reader :scanner

    def tokenize
      @q = []

      until scanner.eos?
        if @is_formula
          case
          when match = scanner.scan(/\"(\\.|[^"\\])*\"/)
            @q << [:QUOTED_STRING, match]
          when match = scanner.scan(/\=/)
            @q << [:EQ, match]
          when match = scanner.scan(/\,/)
            @q << [:COMMA, match]
          when match = scanner.scan(/\(/)
            @q << [:OPEN_PAREN, match]
          when match = scanner.scan(/\)/)
            @q << [:CLOSE_PAREN, match]
          when match = scanner.scan(/\d+[-]\d+[-]\d+/)
            @q << [:DATE_TIME, match]
          when match = scanner.scan(/\d+\.\d+/)
            @q << [:FLOAT, match]
          when match = scanner.scan(/\d+/)
            @q << [:INTEGER, match]
          when match = scanner.scan(/\d+\:\d+/)
            @q << [:TIME, match]
          when match = scanner.scan(/[a-zA-Z][a-zA-Z0-9\_\-]+/)
            @q << [:ID, match]
          when match = scanner.scan(/\./)
            @q << [:DOT, match]
          when scanner.scan(/\s+/)
            #ignore whitespace
          when match = scanner.scan(/.+/)
            @q << [:TEXT, match]
          else
            raise "Unknown token!"
          end
        else
          case
          when match = scanner.scan(/\d+[-\/]\d+[-\/]\d+( \d+\:\d+(\:\d+)?)?/)
            @q << [:DATE_TIME, match]
          when match = scanner.scan(/\d+\.\d+/)
            @q << [:FLOAT, match]
          when match = scanner.scan(/\d+/)
            @q << [:INTEGER, match]
          when match = scanner.scan(/.+/)
            @q << [:TEXT, match]
          end
        end
      end

      @q.push [false, '$end']
      @q
    end
  end
end
