module NewExcel
  module AST
    class BaseAST
      extend Memoist

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

      def debug(msg)
        return unless debug?
        require 'date'
        puts "DEBUG #{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}: #{msg}"
      end

      def debug_indented(msg)
        debug("  #{msg}")
      end

      def debug?
        ProcessState.debug
      end
    end

    class SheetAST < BaseAST
      def value(options={})
        options[:with_header] = true unless options.has_key?(:with_header)
        with_header = options[:with_header]
        only_columns = options[:only_columns]
        only_rows = options[:only_rows]

        if only_columns
          column_indexes = only_columns.map do |column|
            if column.is_a?(String)
              val = column_names.index(column)
              if !val
                raise "Unknown column: #{column.inspect}; columns are: #{column_names.inspect}"
              end
              val
            elsif column.is_a?(Integer)
              column - 1
            else
              raise "Unknown column type!"
            end
          end
        end

        if only_rows
          row_indexes = only_rows
        end

        [].tap do |value|
          if with_header
            value << column_names
          end

          get_body_values(column_indexes, row_indexes).each do |val|
            value << val
          end
        end
      end

      memoize :value

      def get_body_values(column_indexes, row_indexes)
        raise NotImplementedError, "Must be implemented in subclass"
      end
    end

    class DataFile < SheetAST
      attr_accessor :body

      def columns
        body.rows.first
      end

      def column_names
        columns.value.map(&:strip)
      end

      def body_csv
        body.rows[1..(body.rows.length)]
      end

      def get_body_values(column_indexes, row_indexes)
        body_values = body_csv

        if max_rows_to_load = NewExcel::ProcessState.max_rows_to_load
          count = 1

          body_values = body_values.select do |_row|
            (count <= max_rows_to_load).tap do
              count += 1
            end
          end
        end

        NewExcel::Event.fire(Event::GET_BODY_VALUES, length: body_values.length)

        body_values = body_values.map do |column|
          values_for_column = column.value

          if column_indexes
            values_for_column = column_indexes.map { |i| values_for_column[i] }
          end

          values_for_column
        end

        if row_indexes
          body_values = row_indexes.map do |row_index|
            body_values[row_index-1]
          end
        end

        body_values
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
        cells.map(&:value).tap do
          NewExcel::Event.fire(Event::INCREMENT_BODY_VALUE)
        end
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

      def get_body_values(column_indexes, row_indexes)
        index = 0

        # select only the columns that match column_indexes
        kv_pairs = pairs.select do |kv_pair|
          val = !column_indexes || column_indexes.include?(index)
          index += 1
          val
        end

        # get their values
        values_by_column = kv_pairs.map(&:pair_value)

        Event.fire(Event::DEBUG_MAP, self, values_by_column, kv_pairs)

        # select only the values that match row_indexes
        if row_indexes
          values_by_column = values_by_column.map do |values_for_one_column|
            row_indexes.map do |row_index|
              values_for_one_column[row_index-1]
            end
          end
        end

        column_length = values_by_column.map { |col| col.length }.max

        # transpose!
        # normally in
        # [
        #   ["col1", "col 1 val 1", "col 1 val 2"],
        #   ["col2", "col 2 val 1", "col 2 val 2"]
        # ]
        # we want it in:
        # [
        #   ["col1",        "col2"],
        #   ["col 1 val 1", "col 2 val 1"],
        #   ["col 1 val 2", "col 2 val 2"],
        # ]
        body_values = []

        1.upto(column_length) do |num|
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

        Event.fire(Event::DEBUG_FUNCTION, self, evaluated_arguments)

        NewExcel::BuiltInFunctions.public_send(name, *evaluated_arguments).tap do |val|
          Event.fire(Event::DEBUG_FUNCTION_RESULT, self, val)
        end
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

    class UnquotedStringIdFallThrough < UnquotedString
    end

    class DateTime < BaseAST
      def value
        Chronic.parse(string, hours24: true, guess: :begin)
      end
    end
  end
end
