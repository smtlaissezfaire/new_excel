module NewExcel
  class Data
    def initialize(file_path, type)
      @file = file_path
      @file_path = ::File.dirname(@file)
      parse
    end

    attr_reader :file_path

    def raw_map
      @raw_map ||= ::File.read(@file)
    end

    def parse
      @parsed_file ||= CSV.parse(raw_map)
      @columns = @parsed_file.shift
      @all_rows = @parsed_file
    end

    def columns
      @columns
    end

    def get(val=nil)
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
