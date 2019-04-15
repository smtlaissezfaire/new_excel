module NewExcel
  class Data < Sheet
    def parse
      return if @parsed

      @ast = parser.parse("DataFile!\n" + raw_content)

      @column_names = @ast.column_names
      @ast.value

      @parsed = true
    end
  end
end
