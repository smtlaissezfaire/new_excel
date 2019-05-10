module NewExcel
  class File
    TYPES = [
      CSV = "csv",
      MAP = "map",
      ADHOC = "adhoc"
    ]

    class << self
      def open(file)
        if ProcessState.file_cache[file]
          ProcessState.file_cache[file]
        else
          new(file).tap do |obj|
            ProcessState.file_cache[file] = obj
          end
        end
      end
    end

    def initialize(file_name = nil)
      @sheets = []
      @sheet_names = []
      @loaded_sheets = []
      @sheet_name_to_file_type = {}
      @files_by_sheet_name = {}

      if file_name
        if !Dir.exists?(file_name)
          raise Errno::ENOENT, "file: #{file_name} does not exist"
        end

        @file_name = file_name

        load_sheet_names
      end
    end

    attr_reader :sheets
    attr_reader :file_name
    attr_reader :sheet_names
    attr_reader :loaded_sheets

    def load_sheet(sheet_name)
      @loaded_sheets << sheet_name
    end

    def get_sheet(sheet_name)
      if sheet_cache[sheet_name]
        sheet_cache[sheet_name]
      else
        file = @files_by_sheet_name[sheet_name]
        type = @sheet_name_to_file_type[sheet_name]

        obj = if type == MAP
          Map.new(file)
        elsif type == CSV
          Data.new(file)
        elsif type == ADHOC
          Adhoc.new(file)
        end

        sheet_cache[sheet_name] = obj
        obj
      end
    end

  private

    def sheet_cache
      @sheet_cache ||= {}
    end

    def load_sheet_names
      TYPES.each do |type|
        Dir.glob(::File.join(file_name, "*.#{type}")).each do |file|
          sheet_name = ::File.basename(file, ::File.extname(file)).to_s

          @files_by_sheet_name[sheet_name] = file
          @sheet_name_to_file_type[sheet_name] = type

          @sheet_names << sheet_name
        end
      end
    end
  end
end
