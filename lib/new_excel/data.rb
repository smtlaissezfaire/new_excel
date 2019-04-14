module NewExcel
  class Data < Sheet
    def parse
      return if @parsed

      @parsed_file = CSV.parse(raw_content)
      @column_names = @parsed_file.shift
      @all_rows = @parsed_file

      @parsed = true
    end

    def get(val=nil)
      parse

      if val.is_a?(String) || val.is_a?(Integer)
        index = if val.is_a?(String)
          @column_names.index(val)
        else
          val-1
        end

        @all_rows.map do |line|
          line[index]
        end
      elsif val.is_a?(Hash) || val.nil?
        array = []
        if val && val[:with_header]
          array << @column_names
        end
        array += @all_rows
        array
      end
    end

    def evaluate(*args)
      Evaluator.evaluate(self, get(*args))
    end
  end
end
