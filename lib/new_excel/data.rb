module NewExcel
  class Data < Sheet
    def parse
      return if @parsed

      set_process_state do
        @csv = CSV.parse(raw_content)

        @ast = AST::DataFile.new(@sheet_file_path)
        @ast.body = @csv

        @column_names = @ast.column_names

        @parsed = true
      end
    end
  end
end
