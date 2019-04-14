module NewExcel
  class Parser
    class BaseAST
      def initialize(string)
        @string = string
      end

      attr_reader :string

      def value
        raise NotImplementedError, "must implement value in base classes"
      end
    end

    class FunctionCall < BaseAST
      attr_accessor :name
      attr_accessor :arguments

      def value
        evaluated_arguments = arguments.map(&:value)
        NewExcel::BuiltInFunctions.public_send(name, *evaluated_arguments)
      end
    end

    class CellReference < BaseAST
      attr_accessor :sheet_name
      attr_accessor :cell_name

      def value
        file_path = ::File.join($context_file_path, "#{sheet_name}.csv")
        NewExcel::Data.new(file_path, 'csv').evaluate(cell_name)
      end
    end

    class PrimitiveInteger < BaseAST
      def value
        string.to_i
      end
    end

    class PrimitiveFloat < BaseAST
      def value
        string.to_f
      end
    end

    class QuotedString < BaseAST
      def value
        string[1..string.length-2]
      end
    end

    class UnquotedString < BaseAST
      def value
        string
      end
    end

    class DateTime < BaseAST
      def value
        Chronic.parse(string, hours24: true, guess: :begin)
      end
    end

    # thank you - https://martinfowler.com/bliki/HelloRacc.html
    def self.get_tokens(str)
      str = str.strip

      is_formula = str[0] == "="

      scanner = StringScanner.new(str)

      @q = []
      until scanner.eos?
        if is_formula
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

    def parse(str)
      parser = NewExcelGrammarParser.new
      parser.parse(str)
    end
  end
end
