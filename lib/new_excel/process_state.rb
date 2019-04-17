module NewExcel
  class ProcessState
    class << self
      def reset!
        self.reset_file_cache!
        self.current_file_path = nil
        self.current_sheet = nil
        self.max_rows_to_load = nil
        self.debug = false
      end

      attr_accessor :current_file_path
      attr_accessor :current_sheet
      attr_accessor :max_rows_to_load
      attr_accessor :debug

      def current_file
        if current_file_path
          NewExcel::File.open(current_file_path)
        end
      end

      def current_sheet_name
        current_sheet.sheet_name if current_sheet
      end

      def file_cache
        @file_cache ||= {}
      end

      def reset_file_cache!
        @file_cache = {}
      end
    end
  end
end
