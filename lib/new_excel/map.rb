module NewExcel
  class Map
    include ListHelpers

    def initialize(file)
      @file = file
      @file_path = ::File.dirname(@file)
      @column_names = []
      @values = {}
    end

    attr_reader :file_path

    def parse
      return if @parsed

      last_column_name = nil

      raw_content.each_line do |line|
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

      @parsed = true
    end

    def column_names
      parse
      @column_names
    end

    alias_method :columns, :column_names

    def raw_content
      @raw_content ||= ::File.read(@file)
    end

    def get(column_or_column_names = column_names)
      parse

      if column_or_column_names.is_a?(Array)
        column_or_column_names.map do |column_name|
          get(column_name)
        end
      else
        column_name = column_or_column_names

        raise "Column #{column_name.inspect} not found!" if !@values.has_key?(column_name)
        @values[column_name]
      end
    end

    alias_method :raw_value_for, :get

    def evaluate(*args)
      if args.empty?
        args = [column_names]
      end

      ambiguous_map(*args) do |column_name, index|
        val = Evaluator.evaluate(self, get(column_name))

        if index
          val[index-1]
        else
          val
        end
      end
    end

    def read
      evaluate
    end
  end
end
