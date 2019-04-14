module NewExcel
  module AST
    class BaseAST
      def initialize(string)
        @string = string
      end

      attr_reader :string

      def value
        raise NotImplementedError, "must implement value in base classes"
      end

      def print
        string
      end
    end

    class DataFile < BaseAST
      attr_accessor :body

      def csv
        parse_csv!
        @csv
      end

      def columns
        parse_csv!
        @columns
      end

      def body_csv
        parse_csv!
        @body_csv
      end

      def value(options={})
        # is this crazy?
        @value ||= begin
          [].tap do |value|
            if options[:with_header] || !options.has_key?(:with_header)
              value << columns
            end

            body_csv.each do |row|
              value << row.map do |cell|
                parser.parse(cell).value
              end
            end
          end
        end
      end

    private

      def parser
        @parser ||= NewExcel::Parser.new
      end

      def parse_csv!
        @csv ||= begin
          full_csv = CSV.parse(body)
          @columns = full_csv.shift
          @body_csv = full_csv
        end
      end
    end

    class Map < BaseAST
      def initialize(*args)
        super
        @key_value_pairs = []
      end

      def add_pair(pair)
        @key_value_pairs << pair
      end

      def pairs
        @key_value_pairs
      end

      def columns
        @key_value_pairs.map(&:hash_key)
      end

      def get_column(name)
        @key_value_pairs.detect do |kv_pair|
          kv_pair.hash_key == name
        end
      end

      def value
        @key_value_pairs.map(&:value)
      end

      def print
        @key_value_pairs.map do |kv_pair|
          kv_pair.print
        end.join("\n")
      end
    end

    class KeyValuePair < BaseAST
      attr_accessor :hash_key
      attr_accessor :hash_value

      def value
        [hash_key, hash_value.value]
      end

      def print
        "#{hash_key}:\n#{hash_value}"
      end
    end

    class FormulaBody < BaseAST
      attr_accessor :body

      def value
        body.value
      end

      def print
        "= #{body.print}"
      end
    end

    class FunctionCall < BaseAST
      attr_accessor :name
      attr_accessor :arguments

      def value
        evaluated_arguments = arguments.map(&:value)
        NewExcel::BuiltInFunctions.public_send(name, *evaluated_arguments)
      end

      def print
        "#{name}(#{arguments.map(&:print).join(", ")})"
      end
    end

    class CellReference < BaseAST
      attr_accessor :sheet_name
      attr_accessor :cell_name

      def value
        file_path = ::File.join($context_file_path, "#{sheet_name}.csv")
        NewExcel::Data.new(file_path).evaluate(cell_name)
      end

      def print
        "#{sheet_name}.#{cell_name}"
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
        string.chomp
      end
    end

    class DateTime < BaseAST
      def value
        Chronic.parse(string, hours24: true, guess: :begin)
      end
    end
  end
end
