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

    def get(*a, &b)
      raise NotImplementedError, "must be implemented in subclasses"
    end

    def evaluate(*a, &b)
      raise NotImplementedError, "must be implemented in subclasses"
    end
  end
end
