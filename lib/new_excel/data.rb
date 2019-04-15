module NewExcel
  class Data < Sheet
    def parse
      return if @parsed

      # @parsed_file = CSV.parse(raw_content)
      # @column_names = @parsed_file.shift
      # @all_rows = @parsed_file

      @ast = parser.parse("DataFile!\n" + raw_content)

      @column_names = @ast.column_names
      @ast.value

      @parsed = true
    end

    # def get(val=nil)
    #   parse
    #
    #   if val.is_a?(String) || val.is_a?(Integer)
    #     index = if val.is_a?(String)
    #       @column_names.index(val)
    #     else
    #       val-1
    #     end
    #
    #     @all_rows.map do |line|
    #       line[index]
    #     end
    #   elsif val.is_a?(Hash) || val.nil?
    #     val ||= {}
    #
    #     @ast.value(val)
    #     # array += @ast.print
    #     # array
    #   end
    # end

    def evaluate(*args)
      parse

      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:with_header] = false unless options[:with_header]

      if args && args.any?
        options[:only_rows] = args
      end

      @ast.value(options)

      # Evaluator.evaluate(self, get(*args))
    end

  private

    def parser
      @parser ||= Parser.new
    end
  end
end
