require 'spec_helper'

describe NewExcel::Map do
  describe "with simple text" do
    before do
      @file = File.join("spec", "fixtures", "file.ne", "simple_text.map")
      @obj = NewExcel::Map.new(@file)
    end

    it "should be able to read a simple string value" do
      @obj.evaluate("String").should == "a string"
    end

    it "should evaluate an integer" do
      @obj.evaluate("Integer").should == 123
    end

    it "should evaluate a floating point" do
      @obj.evaluate("Float").should == 123.456
    end

    it "should evaluate a Date" do
      @obj.evaluate("Date").should == Time.parse("2018-01-01 00:00:00")
    end

    it "should evaluate a Time" do # FIXME?
      @obj.evaluate("Time").should == "11:00"
    end

    it "should evaluate a DateTime" do
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
      @file = File.join("spec", "fixtures", "file.ne", "map.map")
      @obj = NewExcel::Map.new(@file)
    end

    it "should be able to read a map" do
      @obj.raw_map.should == File.read(@file)
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
      @obj.evaluate("Time").should == [
        "0:00:00",
        "0:05:00",
        "0:10:00",
        "0:15:00",
        "0:20:00",
        "0:25:00",
        "0:30:00",
        "0:35:00",
        "0:40:00",
      ]

      @obj.evaluate("Time", 1).should == "0:00:00"
      @obj.evaluate("Time", 2).should == "0:05:00"
    end
  end

  describe "with simple formulas" do
    before do
      @file = File.join("spec", "fixtures", "file.ne", "simple_formulas.map")
      @obj = NewExcel::Map.new(@file)
    end

    it "should be able to evaluate simple formula from a data sheet" do
      @obj.evaluate("Range", 1).should == 100 - 25
    end

    it "should be able to evaluate a simple plus formula" do
      @obj.evaluate("Plus", 1).should == 100 + 25
    end

    it "should be able to use primitives" do
      # @obj.evaluate("Plus with Primitive", 1).should == 1 + 1
      @obj.evaluate("Plus with Primitive").should == 1 + 1
    end

    it "should be able to evaluate one formula after another" do
      @obj.evaluate("Plus with Minus", 1).should == 100 + 25 - 1
    end
  end

  describe "data integrity" do
    before do
      @file = File.join("spec", "fixtures", "file.ne", "invalid_double_column.map")
    end

    it "should only allow unique columns" do
      lambda {
        @obj = NewExcel::Map.new(@file)
      }.should raise_error
    end
  end
end
