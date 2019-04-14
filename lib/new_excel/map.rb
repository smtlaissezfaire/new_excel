module NewExcel
  class Map < Sheet
    def initialize(file)
      super(file)
      # @values = {}
    end

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

      # last_column_name = nil
      #
      # raw_content.each_line do |line|
      #   if line =~ /^[A-Za-z0-9]/
      #     column_name = line.gsub(/\:$/, '').strip
      #
      #     # if @column_names.include?(column_name)
      #     #   raise "Duplicate column name: #{column_name.inspect}"
      #     # end
      #     #
      #     # # @column_names << column_name
      #     # @values[column_name] ||= ""
      #     last_column_name = column_name
      #   elsif last_column_name
      #     @values[last_column_name] << line
      #   end
      # end
      #
      # @values.each do |key, value|
      #   value.strip!
      # end

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

        @ast.get_column(column_name.to_sym).hash_value.print
      end
    end

    def evaluate(*args)
      parse

      # FIXME: hack hack hack
      $context_file_path = @file_path

      if args.empty?
        args = [column_names]
      end

      ambiguous_map(*args) do |column_name, index|
        val = @ast.get_column(column_name.to_sym).hash_value.value
        # val = Evaluator.evaluate(self, get(column_name, index))

        if index
          val[index-1]
        else
          val
        end
      end
    end

  private

    def parser
      @parser ||= Parser.new
    end
  end
end
