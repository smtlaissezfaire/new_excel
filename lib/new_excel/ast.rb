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

    class SheetAST < BaseAST
      def value(options={})
        options[:with_header] = true unless options.has_key?(:with_header)
        with_header = options[:with_header]
        only_rows = options[:only_rows]

        if only_rows
          row_indexes = only_rows.map do |row|
            if row.is_a?(String)
              val = column_names.index(row)
              raise "Unknown row: #{row.inspect}" if !val
              val
            elsif row.is_a?(Integer)
              row - 1
            else
              raise "Unknown row type!"
            end
          end
        end

        # is this crazy?
        [].tap do |value|
          if with_header
            value << column_names
          end

          get_body_values(row_indexes).each do |val|
            value << val
          end
        end
      end

      def get_body_values(row_indexes)
        raise NotImplementedError, "Must be implemented in subclass"
      end
    end

    class DataFile < SheetAST
      attr_accessor :body

      def columns
        body.rows.first
      end

      def column_names
        columns.value
      end

      def body_csv
        body.rows[1..(body.rows.length)]
      end

      def get_body_values(row_indexes)
        body_values = body_csv.map do |row|
          values_for_row = row.value

          if row_indexes
            row_indexes.map { |i| values_for_row[i] }
          else
            values_for_row
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

    class DataBody < BaseAST
      def initialize(*args)
        @rows = []
      end

      def add_row(row)
        @rows << row
      end

      attr_reader :rows

      def value
        rows.map(&:value)
      end
    end

    class DataRow < BaseAST
      def initialize(*args)
        @cells = []
      end

      def add_cell(cell)
        @cells << cell
      end

      attr_reader :cells

      def value
        cells.map(&:value)
      end
    end

    class DataCell < BaseAST
      attr_accessor :cell_value

      def value
        cell_value.value
      end
    end

    class Map < SheetAST
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

      alias_method :column_names, :columns

      def get_column(name)
        @key_value_pairs.detect do |kv_pair|
          kv_pair.hash_key == name
        end
      end

      def get_body_values(row_indexes)
        index = 0

        kv_pairs = pairs.select do |kv_pair|
          val = !row_indexes || row_indexes.include?(index)
          index += 1
          val
        end

        values_by_column = kv_pairs.map(&:pair_value)
        row_length = values_by_column[0].length

        # want them row by row
        body_values = []

        # transpose!
        1.upto(row_length) do |num|
          body_values << values_by_column.map { |v| v[num - 1] }
        end

        body_values
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
        [pair_key, pair_value]
      end

      def pair_key
        hash_key
      end

      def pair_value
        value = hash_value.value
        if value.is_a?(Array)
          value
        else
          [value]
        end
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
        if sheet_name
          file = NewExcel::ProcessState.current_file
          sheet = file.get_sheet(sheet_name)
        else
          sheet = NewExcel::ProcessState.current_sheet
        end

        raise "No cell name specified! cell_name: #{cell_name.inspect}" if !cell_name

        sheet.evaluate(cell_name).flatten
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
