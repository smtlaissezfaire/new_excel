module NewExcel
  module Console
    def open(file)
      NewExcel::File.open(file)
    end

    def sheet(file)
      dirname = ::File.dirname(file)
      filename = ::File.basename(file, ::File.extname(file))

      open(dirname).get_sheet(filename)
    end
  end
end
