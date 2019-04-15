module NewExcel
  class Sheet
    include ListHelpers

    def initialize(file_path)
      @sheet_file_path = file_path
      @container_file_path = ::File.dirname(@sheet_file_path)
      @column_names = []
    end

    attr_reader :container_file_path

    def column_names
      parse
      @column_names
    end

    alias_method :columns, :column_names

    def raw_content
      @raw_content ||= ::File.read(@sheet_file_path)
    end

    def read
      evaluate
    end

    def raw_value_for(*a, &b)
      get(*a, &b)
    end

    def parse
      raise NotImplementedError, "must be implemented in subclasses"
    end

    #
    # TBD: implement this generically...
    #
    # ***DESIRED*** interface:
    #
    # get = all unevaluated content
    # get() = all columns
    # get(col1, col2, col3)
    # get(1) => col 1
    # get(1, 2) => row 1, col 2
    # get(column_name, 2) => col with column_name, row 2
    # get([col1, col2], 2) => col1 + col2, both with only row 2
    # get(with_header: true) # include the headers
    # get(col1, with_header: true)
    def get(*a, &b)
      raise NotImplementedError, "must be implemented in subclasses"
    end

    def evaluate(*args)
      parse

      set_process_state do
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:with_header] = false unless options[:with_header]

        if args && args.any?
          if args.length >= 2 && (args.last.is_a?(Integer) || args.last.is_a?(Array))
            row_indexes = args.pop
            row_indexes = [row_indexes] if !row_indexes.is_a?(Array)
            options[:only_rows] = row_indexes
          end

          options[:only_columns] = args.flatten
        end

        @ast.value(options)
      end
    end

    def print(*args)
      all_values = evaluate(*args)

      width_per_column = []

      str = ""

      column_names.each_with_index do |column_name, index|
        max_length = column_name.length

        lengths = all_values.map do |row|
          row[index].to_s.length
        end
        max_body_length = lengths.max

        max_length = max_body_length if max_body_length > max_length

        width_per_column << max_length + 1
      end

      last_index = width_per_column.length - 1

      column_names.each_with_index do |column_name, index|
        length = width_per_column[index]
        to_print = column_name.strip

        if index == last_index
          str << to_print
        else
          str << "%-#{length}s" % to_print
        end
      end
      str << "\n"

      column_names.each_with_index do |column_name, index|
        length = width_per_column[index]
        to_print = ("-" * (length - 1))

        if index == last_index
          str << to_print
        else
          str << "%-#{length}s" % to_print
        end
      end
      str << "\n"

      all_values.each do |row|
        row.each_with_index do |cell, index|
          to_print = cell.to_s.strip

          if index == last_index
            str << to_print
          else
            length = width_per_column[index]
            str << "%-#{length}s" % to_print
          end
        end
        str << "\n"
      end

      str
    end

  private

    def parser
      @parser ||= Parser.new
    end

    def set_process_state
      old_file_path = NewExcel::ProcessState.current_file_path
      old_sheet = NewExcel::ProcessState.current_sheet

      NewExcel::ProcessState.current_file_path = @container_file_path
      NewExcel::ProcessState.current_sheet = self

      yield
    ensure
      NewExcel::ProcessState.current_file_path = old_file_path
      NewExcel::ProcessState.current_sheet = old_sheet
    end
  end
end
