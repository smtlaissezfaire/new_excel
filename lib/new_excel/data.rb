module NewExcel
  class Data < Sheet
    def parse
      return if @parsed

      set_process_state do
        @ast = parser.parse("DataFile!\n" + raw_content)

        @column_names = @ast.column_names

        @parsed = true
      end
    end
  end
end
