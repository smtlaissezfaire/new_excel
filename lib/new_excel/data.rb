module NewExcel
  class Data < Sheet
    extend Memoist

    def parse
      return if @parsed

      set_process_state do
        @csv = CSV.parse(raw_content)

        # @ast = AST::DataFile.new(@sheet_file_path)
        @body = @csv
        @column_names = @body.first.map(&:strip)

        # @column_names = @ast.column_names

        @parsed = true
      end
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

    attr_accessor :body

    # def columns
    #   body.first
    # end
    #
    # def column_names
    #   columns.map(&:strip)
    # end

    def body_csv
      body[1..(body.length)]
    end
  end
end
