$LOAD_PATH << "./lib"

require 'pp'
require 'new_excel'
require 'byebug'

include NewExcel
extend NewExcel::Console

ProcessState.debug = false

# file = NewExcel::File.new("./spec/fixtures/file.ne")
#
# # sheet = file.get_sheet('simple_text')
# # puts sheet.for_printing
#
# # s = sheet "spec/fixtures/file.ne/map.map";
# # print s.for_printing
#
# # puts ""
# #
# # sheet = file.get_sheet('rows_for_printing')
# # puts sheet.for_printing
# #
# # puts ""
# #
# # sheet = file.get_sheet('one_column_map')
# # puts sheet.for_printing
# #
# # puts ""
# #
# # sheet = file.get_sheet('two_column_map')
# # puts sheet.for_printing
# #
# sheet = file.get_sheet("relative_references")
# puts sheet.for_printing
#

###################################################

file = NewExcel::File.new("./file.ne")

ProcessState.max_rows_to_load = 1000

# sheet = file.get_sheet('zf_mapped_dates')
# sheet = file.get_sheet('zf_mapped_data')
# sheet = file.get_sheet('adx')
sheet = file.get_sheet('stochastic')
# pp sheet.read
puts sheet.for_printing

# # sheet = file.get_sheet("ZCTest2")
# #
# # puts sheet.for_printing
#
# sheet = file.get_sheet("moving_average")
# print sheet.for_printing
