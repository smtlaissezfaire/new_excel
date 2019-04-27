module NewExcel
  class Map < Sheet
    extend Memoist

    def parse
      set_process_state do
        return if @parsed

        @ast = parser.parse(raw_content)

        @ast.to_hash.keys.map { |col| col.to_s }.each do |column_name|
          if @column_names.include?(column_name)
            raise "Duplicate column name: #{column_name.inspect}"
          end

          @column_names << column_name
        end

        @parsed = true
      end
    end

    def evaluate(obj, env)
      evaluator.evaluate(obj, env)
    end

    def evaluator
      @evaluator ||= Evaluator.new
    end

    def get(column_or_column_names = column_names)
      parse

      if column_or_column_names.is_a?(Array)
        column_or_column_names.map do |column_name|
          get(column_name)
        end
      else
        column_name = column_or_column_names
        @ast.to_hash[column_name.to_sym].for_printing
      end
    end

    def environment
      @environment ||= begin
        parse
        Runtime.base_environment
      end
    end

    def evaluated_with_unevaluated_columns
      @evaluated_with_unevaluated_columns ||= begin
        parse
        evaluate(@ast, environment)
      end
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
        key = key.to_sym
        env = environment

        val = evaluate([:lookup, [:quote, key], environment], environment)
        val = [val] unless val.is_a?(Array)

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
  end
end
