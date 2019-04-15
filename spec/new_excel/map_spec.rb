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
      @obj.evaluate("String").should == [["a string"]]
    end

    it "should evaluate an integer" do
      @obj.evaluate("Integer").should == [[123]]
    end

    it "should evaluate a floating point" do
      @obj.evaluate("Float").should == [[123.456]]
    end

    it "should evaluate a Date" do
      pending "FIXME: date parsing not working?"
      @obj.evaluate("Date").should == Time.parse("2018-01-01 00:00:00")
    end

    it "should evaluate a Time" do # FIXME?
      @obj.evaluate("Time").should == [["11:00"]]
    end

    it "should evaluate a DateTime" do
      pending "FIXME: Date parsing not working?"
      @obj.evaluate("DateTime").should == Time.parse("2018-01-01 11:00:00")
    end

    # it "should allow a list of strings" do
    #   @obj.evaluate("List of Strings").should == ["a", "b", "c"]
    # end
    #
    # it "should allow a list of ints" do
    #   @obj.evaluate("List of Ints").should == [1, 2, 3]
    # end
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
      @obj.evaluate("Date").should == [
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

    it "should be able to index in with a second variable" do
      @obj.evaluate("Time").should == [
        [ "0:00", ],
        [ "0:05", ],
        [ "0:10", ],
        [ "0:15", ],
        [ "0:20", ],
        [ "0:25", ],
        [ "0:30", ],
        [ "0:35", ],
        [ "0:40", ],
      ]
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
      @obj.evaluate("Time", "Volume").should == [
        [ "0:00", 653, ],
        [ "0:05", 4, ],
        [ "0:10", 404, ],
        [ "0:15", 1021, ],
        [ "0:20", 521, ],
        [ "0:25", 256, ],
        [ "0:30", 226, ],
        [ "0:35", 938, ],
        [ "0:40", 262 ],
      ]
    end

    it "should be able to evaluate two columns with an index" do
      pending "FIXME"
      @obj.evaluate(["Time", "Volume"], 1).should == ["0:00:00", 653]
      @obj.evaluate(["Time", "Volume"], 2).should == ["0:05:00", 4]
    end

    it "should be able to evaluate two columns with two indexes" do
      pending "FIXME"
      @obj.evaluate(["Time", "Volume"], [2, 3]).should == ["0:05:00", 404]
    end

    it "should be able to load all data with read()" do
      result = @obj.read
      result.length.should == 9

      result[0].length.should == 10

      first_data_row = result[0]

      first_data_row[0].should be_a_kind_of(Time)
      # FIXME:
      # first_data_row[1].should == "0:00:00"
      # first_data_row[2].should == "114 16.75/32"
      # first_data_row[3].should == "114 17/32"
      # first_data_row[4].should == "114 16.75/32"
      # first_data_row[5].should == "114 16.75/32"
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
      @obj.evaluate("Range").should == [[100 - 25]]
    end

    it "should be able to evaluate a simple plus formula" do
      @obj.evaluate("Plus").should == [[100 + 25]]
    end

    it "should be able to use primitives" do
      # @obj.evaluate("Plus with Primitive", 1).should == 1 + 1
      @obj.evaluate("Plus with Primitive").should == [[1 + 1]]
    end

    it "should be able to evaluate one formula after another" do
      @obj.evaluate("Plus with Minus").should == [[100 + 25 - 1]]
    end

    it "should be able to read a simple string value evaluated" do
      @obj.evaluate("String Evaluated").should == [["a string evaluated"]]
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
String   Integer Float   Date Time  DateTime List of Strings List of Ints
-------- ------- ------- ---- ----- -------- --------------- ------------
a string 123     123.456 0    11:00 0        a b c           123
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
  end

  # describe "self-referencing" do
  #   before do
  #     @obj = basic_file.get_sheet("self_referential")
  #   end
  #
  #   it "should be able to refer to one of it's own columns through the sheet" do
  #     pending "FIXME"
  #     @obj.evaluate("One").should == [[1]]
  #     @obj.evaluate("ReferencingOneIndirectly").should == [[1]]
  #   end
  # end
end
