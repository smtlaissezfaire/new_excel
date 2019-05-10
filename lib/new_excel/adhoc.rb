module NewExcel
  class Adhoc < Sheet
    extend Memoist

    def parse
      return if @parsed_content

      parsed_content = CSV.parse(raw_content, col_sep: "|", quote_char: "\\")
      # parsed_content = raw_content.split("\n").map do |line|
      #   line.split("|")
      # end

      # @ast = AST::DataFile.new(@sheet_file_path)
      parsed_content = parsed_content.map do |line|
        line.map do |element|
          element.strip
        end
      end

      @parsed_content = parsed_content
    end

    def parsed_content
      parse
      @parsed_content
    end

    def evaluate
      return if @evaluated

      set_process_state do
        @body = parsed_content.map do |row|
          row = row.map do |cell|
            evaluate_cell(cell)
          end
        end

        @evaluated = true
      end
    end

    def get_body_values(column_indexes, row_indexes)
      body_values = body

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

    def body
      evaluate
      @body
    end

  private

    def evaluator
      @evaluator ||= NewExcel::Evaluator.new
    end

    def evaluate_cell(expr)
      if expr =~ /^[\s]*\=.*/
        closure = evaluator.evaluate(evaluator.parse(expr))
        value = evaluator.evaluate([closure])

        if value.is_a?(Array)
          if value.length == 1
            value[0]
          else
            value.join(" ")
          end
        else
          value
        end
      else
        expr
      end
    end
  end
end
