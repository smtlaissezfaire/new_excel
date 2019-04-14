module NewExcel
  class Data
    def initialize(file_path)
      @file = file_path
      @file_path = ::File.dirname(@file)
    end

    attr_reader :file_path

    def raw_content
      @raw_content ||= ::File.read(@file)
    end

    def parse
      return if @parsed

      @parsed_file = CSV.parse(raw_content)
      @columns = @parsed_file.shift
      @all_rows = @parsed_file

      @parsed = true
    end

    def columns
      parse
      @columns
    end

    def get(val=nil)
      parse

      if val.is_a?(String) || val.is_a?(Integer)
        index = if val.is_a?(String)
          @columns.index(val)
        else
          val-1
        end

        @all_rows.map do |line|
          line[index]
        end
      elsif val.is_a?(Hash) || val.nil?
        array = []
        if val && val[:with_header]
          array << @columns
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
