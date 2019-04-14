module NewExcel
  class File
    TYPES = [
      CSV = "csv",
      MAP = "map",
    ]

    def self.open(file)
      new(file)
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
      file = @files_by_sheet_name[sheet_name]
      type = @sheet_name_to_file_type[sheet_name]

      if type == MAP
        Map.new(file)
      elsif type == CSV
        Data.new(file)
      end
    end

  private

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
