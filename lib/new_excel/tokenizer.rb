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
      @is_data_file = str =~ /^DataFile\!/
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
        if @is_data_file
          case
          when match = scanner.scan(/DataFile\!\n/)
            @q << [:DATA_FILE, match]
          else
            remaining = scanner.rest
            scanner.terminate

            csv = CSV.parse(remaining)
            csv.each do |row|
              row.each do |cell_text|
                cell_scanner = StringScanner.new(cell_text)

                # primitives
                case
                when token_pair = tokens_for_primitive_match(cell_scanner)
                  @q << token_pair
                else # when match = scanner.scan(/(.+)\n?/)
                  @q << [:TEXT, cell_text]
                end
              end

              @q << [:CSV_END_OF_ROW, true]
            end

            @q << [:CSV_END_OF_FILE, true]
          end
        elsif @is_map || @is_formula
          case
          when match = scanner.scan(/\"(\\.|[^"\\])*\"/)
            @q << [:QUOTED_STRING, match]
          # when match = scanner.scan(/Map\!/)
          #   @q << [:MAP, match]
          when match = scanner.scan(/Map\!/)
            @q << [:MAP, match]
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
          when match = scanner.scan(/[a-zA-Z][a-zA-Z0-9\_\-]+/)
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
      when match = scanner.scan(/\d+/)
        [:INTEGER, match]
      end
    end

    def tokens_for_text_scan(scanner)
      if match = scanner.scan(/(.+)\n?/)
        [:TEXT, match]
      end
    end
  end
end
