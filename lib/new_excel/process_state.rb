module NewExcel
  class ProcessState
    class << self
      def reset!
        self.reset_file_cache!
        self.current_file_path = nil
        self.current_sheet = nil
      end

      attr_accessor :current_file_path
      attr_accessor :current_sheet

      def current_file
        if current_file_path
          NewExcel::File.open(current_file_path)
        end
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
