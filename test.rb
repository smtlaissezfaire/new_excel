$LOAD_PATH << "./lib"

require 'pp'
require 'new_excel'
require 'byebug'

include NewExcel

# file = NewExcel::File.new("./spec/fixtures/file.ne")
#
# sheet = file.get_sheet('simple_text')
# puts sheet.print
#
# puts ""
#
# sheet = file.get_sheet('rows_for_printing')
# puts sheet.print
#
# puts ""
#
# sheet = file.get_sheet('one_column_map')
# puts sheet.print
#
# puts ""
#
# sheet = file.get_sheet('two_column_map')
# puts sheet.print


###################################################

file = NewExcel::File.new("./file.ne")

ProcessState.max_rows_to_load = 10000

# sheet = file.get_sheet('zf_mapped_data')
# # pp sheet.read
# puts sheet.print

sheet = file.get_sheet("ZCTest2")

puts sheet.print
