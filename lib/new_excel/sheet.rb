module NewExcel
  class Sheet
    include ListHelpers

    def initialize(file_path)
      @file = file_path
      @file_path = ::File.dirname(@file)
      @column_names = []
    end

    attr_reader :file_path

    def column_names
      parse
      @column_names
    end

    alias_method :columns, :column_names

    def raw_content
      @raw_content ||= ::File.read(@file)
    end

    def read
      evaluate
    end

    def raw_value_for(*a, &b)
      get(*a, &b)
    end

    def parse
      raise NotImplementedError, "must be implemented in subclasses"
    end

    # ***DESIRED*** interface:
    #
    # get = all unevaluated content
    # get() = all columns
    # get(col1, col2, col3)
    # get(1) => col 1
    # get(1, 2) => row 1, col 2
    # get(column_name, 2) => col with column_name, row 2
    # get([col1, col2], 2) => col1 + col2, both with only row 2
    # get(with_header: true) # include the headers
    # get(col1, with_header: true)
    def get(*a, &b)
      raise NotImplementedError, "must be implemented in subclasses"
    end

    def evaluate(*a, &b)
      raise NotImplementedError, "must be implemented in subclasses"
    end
  end
end
