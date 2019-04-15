module NewExcel
  class Map < Sheet
    def parse
      return if @parsed

      content = "Map!\n#{raw_content}"
      @ast = parser.parse(content)
      @ast.columns.map { |col| col.to_s }.each do |column_name|
        if @column_names.include?(column_name)
          raise "Duplicate column name: #{column_name.inspect}"
        end

        @column_names << column_name
      end

      @parsed = true
    end

    def get(column_or_column_names = column_names)
      parse

      if column_or_column_names.is_a?(Array)
        column_or_column_names.map do |column_name|
          get(column_name)
        end
      else
        column_name = column_or_column_names
        # raise "Column #{column_name.inspect} not found!" if !@values.has_key?(column_name)
        # @values[column_name]

        @ast.get_column(column_name).hash_value.print
      end
    end
  end
end
