$LOAD_PATH << "./lib"

require 'pp'
require 'new_excel'

file = NewExcel::File.new("./file.ne")

sheet = file.get_sheet('zf_mapped_data')
pp sheet.read
