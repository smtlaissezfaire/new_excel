require 'spec_helper'

describe NewExcel::Map do
  def basic_file
    @file = NewExcel::File.open(File.join("spec", "fixtures", "file.ne"))
  end

  describe "with simple text" do
    before do
      @obj = basic_file.get_sheet("simple_text")
    end

    it "should be able to read a simple string value" do
      @obj.filter("String").should == [["a string"]]
    end

    it "should evaluate an integer" do
      @obj.filter("Integer").should == [[123]]
    end

    it "should evaluate a floating point" do
      @obj.filter("Float").should == [[123.456]]
    end

    it "should evaluate a Date" do
      @obj.filter("Date").should == [[Time.parse("2018-01-01 00:00:00")]]
    end

    it "should evaluate a Time" do # FIXME?
      @obj.filter("Time").should == [["11:00"]]
    end

    it "should evaluate a DateTime" do
      @obj.filter("DateTime").should == [[Time.parse("2018-01-01 11:00:00")]]
    end
  end

  describe "with a simple map" do
    before do
      @obj = basic_file.get_sheet("map")
    end

    it "should be able to read a map" do
      @obj.raw_content.should == File.read(File.join(basic_file.file_name, "map.map"))
    end

    it "should be able to list the columns" do
      @obj.columns.should == %w(
        Date
        Time
        Open
        High
        Low
        Close
        Volume
        NumberOfTrades
        BidVolume
        AskVolume
      )
    end

    it "should have the raw value for a column" do
      @obj.raw_value_for("Date").should == "= original_data.Date"
    end

    it "should be able to evaluate to the original data map" do
      @obj.filter("Date").should == [
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
        [ Time.parse("2019/03/01") ],
      ]
    end

    it "should be able to get the column directly as an array (instead of as a filtered sheet)" do
      @obj.get_column("Date").should == [
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
        Time.parse("2019/03/01"),
      ]
    end

    it "should be able to index in with a second variable" do
      @obj.filter("Time", 1).should == [ [ "0:00:00", ] ]
    end

    it "should be able to get multiple columns of the data (unevaluated)" do
      @obj.get(["Date", "Time"]).should == [
        "= original_data.Date",
        "= original_data.Time",
      ]
    end

    it "should return all columns if none specified" do
      @obj.get().should == [
        "= original_data.Date",
        "= original_data.Time",
        "= original_data.Open",
        "= original_data.High",
        "= original_data.Low",
        "= original_data.Close",
        "= original_data.Volume",
        "= multiply(original_data.NumberOfTrades, 2)",
        "= original_data.BidVolume",
        "= original_data.AskVolume",
      ]
    end

    it "should be able to evaluate two columns" do
      @obj.filter("Time", "Volume").should == [
        [ "0:00:00", 653, ],
        [ "0:05:00", 4, ],
        [ "0:10:00", 404, ],
        [ "0:15:00", 1021, ],
        [ "0:20:00", 521, ],
        [ "0:25:00", 256, ],
        [ "0:30:00", 226, ],
        [ "0:35:00", 938, ],
        [ "0:40:00", 262 ],
      ]
    end

    it "should be able to evaluate two columns with an index" do
      @obj.filter(["Time", "Volume"], 1).should == [["0:00:00", 653]]
      @obj.filter(["Time", "Volume"], 2).should == [["0:05:00", 4]]
    end

    it "should be able to evaluate two columns with two indexes" do
      @obj.filter(["Time", "Volume"], [2, 3]).should == [["0:05:00", 4], ["0:10:00", 404]]
    end

    it "should be able to load all data with read()" do
      result = @obj.read
      result.length.should == 9

      result[0].length.should == 10

      first_data_row = result[0]

      first_data_row[0].should be_a_kind_of(Time)
      first_data_row[1].should == "0:00:00"
      first_data_row[2].should == "114 16.75/32"
      first_data_row[3].should == "114 17/32"
      first_data_row[4].should == "114 16.75/32"
      first_data_row[5].should == "114 16.75/32"
      first_data_row[6].should == 653
      first_data_row[7].should == 214
      first_data_row[8].should == 524
      first_data_row[9].should == 129
    end
  end

  describe "with simple formulas" do
    before do
      @obj = basic_file.get_sheet("simple_formulas")
    end

    it "should be able to evaluate simple formula from a data sheet" do
      @obj.filter("Range").should == [[100 - 25]]
    end

    it "should be able to evaluate a simple plus formula" do
      @obj.filter("Plus").should == [[100 + 25]]
    end

    it "should be able to use primitives" do
      # @obj.filter("Plus with Primitive", 1).should == 1 + 1
      @obj.filter("Plus with Primitive").should == [[1 + 1]]
    end

    it "should be able to evaluate one formula after another" do
      @obj.filter("Plus with Minus").should == [[100 + 25 - 1]]
    end

    it "should be able to read a simple string value evaluated" do
      @obj.filter("String Evaluated").should == [["a string evaluated"]]
    end
  end

  describe "data integrity" do
    before do
      @obj = basic_file.get_sheet("invalid_double_column")
    end

    it "should only allow unique columns" do
      lambda {
        @obj.parse
      }.should raise_error(RuntimeError)
    end
  end

  describe "printing" do
    it "should print" do
      @obj = basic_file.get_sheet("simple_text")

      @obj.print.should == <<-STR
String   Integer Float   Date                      Time  DateTime
-------- ------- ------- ------------------------- ----- -------------------------
a string 123     123.456 2018-01-01 00:00:00 -0800 11:00 2018-01-01 11:00:00 -0800
  STR

    end

    it "should print a referenced map correctly" do
      @obj = basic_file.get_sheet("one_column_map")

      @obj.print.should == <<-STR
Date
-------------------------
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800
STR
    end

    it "should be able to reference another column directly, which refers to a csv file" do
      @obj = basic_file.get_sheet("direct_indirect_csv_reference")
      @obj.print.should == <<-STR
DateA                     DateB
------------------------- -------------------------
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
2019-03-01 00:00:00 -0800 2019-03-01 00:00:00 -0800
STR
    end
  end

  describe "self-referencing" do
    before do
      @obj = basic_file.get_sheet("self_referential")
    end

    it "should be able to refer to one of it's own columns through the sheet" do
      @obj.filter("OneValue").should == [[1]]
      @obj.filter("ReferencingOneIndirectly").should == [[1]]
    end

    it "should raise when handling an invalid column reference through the own sheet" do
      lambda {
        @obj.filter("ReferencingOneIndirectlyBadColumnValue")
      }.should raise_error(RuntimeError, /Unknown column: \"InvalidColumnReference\"/)
    end

    it "should be able to refer to one of it's own columns without the sheet" do
      @obj.filter("OneValue").should == [[1]]
      @obj.filter("ReferencingOneDirectly").should == [[1]]
    end
  end

  describe "with different row counts" do
    before do
      @obj = basic_file.get_sheet("array_list")
    end

    it "should list all the values" do
      @obj.filter(with_header: true).should == [
        ["num", "List"],
        [100, 200],
        [nil, 201],
        [nil, 202],
      ]
    end
  end

  describe "comments" do
    before do
      @obj = basic_file.get_sheet("comments")
    end

    it "should list all the values" do
      @obj.filter(with_header: true).should == [
        ["Row1", "Row2"],
        [1, 2],
      ]
    end
  end
end
