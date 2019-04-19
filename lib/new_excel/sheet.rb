module NewExcel
  class Sheet
    include ListHelpers

    def initialize(file_path)
      @sheet_file_path = file_path
      @container_file_path = ::File.dirname(@sheet_file_path)
      @column_names = []
    end

    attr_reader :container_file_path

    def sheet_name
      ::File.basename(@sheet_file_path, ::File.extname(@sheet_file_path)).to_s
    end

    def column_names
      parse
      @column_names
    end

    alias_method :columns, :column_names

    def raw_content
      @raw_content ||= ::File.read(@sheet_file_path)
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

    def filter(*args)
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

    alias_method :read, :filter

    def get_column(column)
      filter(column).map(&:first)
    end

    def print
      Kernel.print for_printing
    end

    def for_printing(*args)
      all_values = filter(*args)

      column_names_for_display = column_names

      if ProcessState.use_colors
        column_names_for_display = column_names.map(&:blue).map(&:bold)
      end

      str = ::Terminal::Table.new({
        style: {
          border_top: false,
          border_bottom: false,
          border_y: ' ',
          border_i: ' ',
        },
        headings: column_names_for_display,
        rows: all_values,
      }).to_s

      str + "\n"
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
