module NewExcel
  class Map
    def initialize(file)
      @file = file
      @file_path = File.dirname(@file)
      @column_names = []
      @values = {}
      parse!
    end

    attr_reader :file_path

    def parse!
      last_column_name = nil

      raw_map.each_line do |line|
        if line =~ /^[A-Za-z0-9]/
          column_name = line.gsub(/\:$/, '').strip

          if @column_names.include?(column_name)
            raise "Duplicate column name: #{column_name.inspect}"
          end

          @column_names << column_name
          @values[column_name] ||= ""
          last_column_name = column_name
        elsif last_column_name
          @values[last_column_name] << line
        end
      end

      @values.each do |key, value|
        value.strip!
      end
    end

    attr_reader :column_names
    alias_method :columns, :column_names

    def raw_map
      @raw_map ||= File.read(@file)
    end

    def get(column_name)
      raise "Column #{column_name.inspect} not found!" if !@values.has_key?(column_name)
      @values[column_name]
    end

    alias_method :raw_value_for, :get

    def evaluate(column_name, index = nil)
      val = Evaluator.evaluate(self, get(column_name))

      if index
        val[index-1]
      else
        val
      end
    end
  end
end
