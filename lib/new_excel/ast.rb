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

      def for_printing
        string
      end

      def debug(msg)
        return unless debug?
        puts "DEBUG #{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}: #{msg}"
      end

      def debug_indented(msg)
        debug("  #{msg}")
      end

      def debug?
        ProcessState.debug
      end

    private

      def catching_errors(&block)
        yield
      rescue => e
        if ProcessState.strict_error_mode
          raise e
        else
          error_string = "!?ERROR"
          error_string = error_string.red if ProcessState.use_colors

          msg = ["#{error_string}: #{e.class}: #{e.message}\n"]
          msg << e.backtrace[0]
          msg.flatten!

          message_split = msg.join("\n").scan(/.{1,60}/)
          msg = message_split.join("\n")

          [msg]
        end
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
        body.first
      end

      def column_names
        columns.map(&:strip)
      end

      def body_csv
        body[1..(body.length)]
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

        body_values = body_values.map do |column|
          values_for_column = column

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
    end

    class Map < SheetAST
      def initialize(*args)
        super
        @environment = RunTime::BaseEnvironment.new
        @key_value_pairs = []
      end

      attr_reader :environment

      def add_pair(pair)
        @key_value_pairs << pair
        @environment[pair.hash_key] = pair.hash_value
      end

      def pairs
        @key_value_pairs
      end

      def columns
        @key_value_pairs.map(&:hash_key)
      end

      alias_method :column_names, :columns

      def get_column(name)
        @environment[name]
      end

      def value(*args, &block)
        val = nil
        ProcessState.set_execution_context(@environment) do
          val = super
        end
        val
      end

      def get_body_values(column_indexes, row_indexes)
        index = 0

        keys = columns

        if column_indexes
          keys_for_selection = column_indexes.map do |index|
            keys[index]
          end
        else
          keys_for_selection = keys
        end

        values_by_column = keys_for_selection.map do |key|
          val = @environment[key].value
          val = [val] if !val.is_a?(Array)
          val
        end

        Event.fire(Event::DEBUG_MAP, self, keys_for_selection, values_by_column)

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

      def for_printing
        @key_value_pairs.map do |kv_pair|
          kv_pair.for_printing
        end.join("\n")
      end
    end

    class KeyValuePair < BaseAST
      attr_accessor :hash_key
      attr_accessor :hash_value

      def value
        [hash_key, hash_value]
      end

      def for_printing
        "#{hash_key}:\n#{hash_value}"
      end
    end

    class Function < BaseAST
      attr_accessor :body
      attr_writer :arguments

      def arguments
        @arguments ||= []
      end

      def arity
        arguments.length
      end

      def value
        body.value
      end

      def for_printing
        "= #{body.for_printing}"
      end
    end

    class FunctionFormalArgument < BaseAST
      attr_accessor :name
    end

    class FunctionCall < BaseAST
      attr_accessor :name
      attr_accessor :arguments

      def environment
        ProcessState.execution_context
      end

      def value
        Event.fire(Event::DEBUG_FUNCTION, self)

        if environment.nil?
          raise "No environment!"
        end

        val = environment[name].call(*arguments)

        val.tap do |val|
          Event.fire(Event::DEBUG_FUNCTION_ARGUMENT, self, arguments)
          Event.fire(Event::DEBUG_FUNCTION_RESULT, self, val)
        end
      end

      memoize :value

      def for_printing
        "#{name}(#{arguments.map(&:for_printing).join(", ")})"
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

        sheet.get_column(cell_name)
      end

      def for_printing
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

    class Boolean < BaseAST
      def value
        string.chomp == "true"
      end
    end
  end
end
