module NewExcel
  class Adhoc < Sheet
    extend Memoist

    def parse
      return if @parsed

      set_process_state do
        @body = csv_content.map do |row|
          row = row.map do |item|
            evaluate(item)
          end
        end

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

    def csv_content
      return @csv_content if @csv_content_parsed

      @csv_content = CSV.parse(raw_content, :col_sep => "|")

      # @ast = AST::DataFile.new(@sheet_file_path)
      @csv_content = @csv_content.map do |line|
        line.map do |element|
          element.strip
        end
      end

      @csv_content_parsed = true
      @csv_content
    end

    attr_accessor :body
    alias_method :body_csv, :body

  private

    def evaluator
      @evaluator ||= NewExcel::Evaluator.new
    end

    def evaluate(expr)
      if expr =~ /^[\s]*\=.*/
        closure = evaluator.evaluate(evaluator.parse(expr))
        evaluator.evaluate([closure])
      else
        expr
      end
    end
  end
end
