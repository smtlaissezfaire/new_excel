Treetop.load File.join(File.expand_path(File.dirname(__FILE__)), 'new_excel_grammar')

module NewExcel
  class Parser
    def parse(str)
      parser = NewExcelGrammarParser.new
      res = parser.parse(str)

      # pp parser.inspect
      if res
        res.evaluate
      else
        pp parser.inspect
        raise parser.failure_reason
      end
    end

    alias_method :evaluate, :parse
  end
end
