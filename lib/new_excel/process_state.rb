module NewExcel
  class ProcessState
    class << self
      attr_accessor :current_file_path

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
