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
      @obj.raw_value_for("Date").should == "= date(original_data.Date)"
    end

    it "should be able to evaluate to the original data map" do
      @obj.filter("Date").should == [
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
        [ Date.parse("2019/03/01") ],
      ]
    end

    it "should be able to get the column directly as an array (instead of as a filtered sheet)" do
      @obj.get_column("Date").should == [
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
        Date.parse("2019/03/01"),
      ]
    end

    it "should be able to index in with a second variable" do
      @obj.filter("Time", 1).should == [
        [ Time.parse("2019-03-01 0:00:00"), ]
      ]
    end

    it "should be able to get multiple columns of the data (unevaluated)" do
      @obj.get(["Date", "Time"]).should == [
        "= date(original_data.Date)",
        "= time(concat(original_data.Date, \" \", original_data.Time))",
      ]
    end

    it "should return all columns if none specified" do
      @obj.get().should == [
        "= date(original_data.Date)",
        "= time(concat(original_data.Date, \" \", original_data.Time))",
        "= original_data.Open",
        "= original_data.High",
        "= original_data.Low",
        "= original_data.Close",
        "= to_number(original_data.Volume)",
        "= multiply(to_number(original_data.NumberOfTrades), 2)",
        "= to_number(original_data.BidVolume)",
        "= to_number(original_data.AskVolume)",
      ]
    end

    it "should be able to evaluate two columns" do
      @obj.filter("Time", "Volume").should == [
        [ Time.parse("2019-03-01 0:00:00"), 653, ],
        [ Time.parse("2019-03-01 0:05:00"), 4, ],
        [ Time.parse("2019-03-01 0:10:00"), 404, ],
        [ Time.parse("2019-03-01 0:15:00"), 1021, ],
        [ Time.parse("2019-03-01 0:20:00"), 521, ],
        [ Time.parse("2019-03-01 0:25:00"), 256, ],
        [ Time.parse("2019-03-01 0:30:00"), 226, ],
        [ Time.parse("2019-03-01 0:35:00"), 938, ],
        [ Time.parse("2019-03-01 0:40:00"), 262 ],
      ]
    end

    it "should be able to evaluate two columns with an index" do
      @obj.filter(["Time", "Volume"], 1).should == [
        [Time.parse("2019-03-01 0:00:00"), 653]
      ]
      @obj.filter(["Time", "Volume"], 2).should == [
        [Time.parse("2019-03-01 0:05:00"), 4]
      ]
    end

    it "should be able to evaluate two columns with two indexes" do
      @obj.filter(["Time", "Volume"], [2, 3]).should == [
        [Time.parse("2019-03-01 0:05:00"), 4],
        [Time.parse("2019-03-01 0:10:00"), 404]
      ]
    end

    it "should be able to load all data with read()" do
      result = @obj.read
      result.length.should == 9

      result[0].length.should == 10

      first_data_row = result[0]

      first_data_row[0].should == Date.parse("2019/03/01")
      first_data_row[1].should == Time.parse("2019/03/01 0:00:00")
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

      @obj.for_printing(colors: false).should == <<-STR
  String     Integer   Float     Date                        Time    DateTime
 ---------- --------- --------- --------------------------- ------- ---------------------------
  a string   123       123.456   2018-01-01 00:00:00 -0800   11:00   2018-01-01 11:00:00 -0800
STR

    end

    it "should print a referenced map correctly" do
      @obj = basic_file.get_sheet("one_column_map")

      @obj.for_printing.should == <<-STR
  Date
 ------------
  2019/03/01
  2019/03/01
  2019/03/01
  2019/03/01
  2019/03/01
  2019/03/01
  2019/03/01
  2019/03/01
  2019/03/01
STR
    end

    it "should be able to reference another column directly, which refers to a csv file" do
      @obj = basic_file.get_sheet("direct_indirect_csv_reference")
      @obj.for_printing.should == <<-STR
  DateA        DateB
 ------------ ------------
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
  2019/03/01   2019/03/01
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

  describe "array formulas on relative references" do
    before do
      @obj = basic_file.get_sheet("relative_references")
    end

    it "should list all the values with a range" do
      @obj.get_column("Value").should == [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    end

    it "should be able to get a count of the values" do
      @obj.get_column("CountAll").should == [11]
    end

    it "should be able to list each of the values" do
      @obj.get_column("Each").should == [
        [10],
        [10, 11],
        [10, 11, 12],
        [10, 11, 12, 13],
        [10, 11, 12, 13, 14,],
        [10, 11, 12, 13, 14, 15],
        [10, 11, 12, 13, 14, 15, 16],
        [10, 11, 12, 13, 14, 15, 16, 17],
        [10, 11, 12, 13, 14, 15, 16, 17, 18],
        [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
        [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
      ]
    end

    it "should be able to get a count of each" do
      @obj.get_column("CountEach").should == [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
      ]
    end

    it "should be able to get an index" do
      @obj.get_column("Index").should == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    end

    it "should be able to get a sum of all" do
      @obj.get_column("Sum").should == [(10..20).sum]
    end

    it "should be able to lookback" do
      @obj.get_column("Lookback5").should == [
        [10],
        [10, 11],
        [10, 11, 12],
        [10, 11, 12, 13],
        [10, 11, 12, 13, 14],
        [10, 11, 12, 13, 14, 15],
        [11, 12, 13, 14, 15, 16],
        [12, 13, 14, 15, 16, 17],
        [13, 14, 15, 16, 17, 18],
        [14, 15, 16, 17, 18, 19],
        [15, 16, 17, 18, 19, 20],
      ]
    end

    it "should be able to get a running sum" do
      @obj.get_column("RunningSum").should == [
        [10].sum,
        [10, 11].sum,
        [10, 11, 12].sum,
        [10, 11, 12, 13].sum,
        [10, 11, 12, 13, 14,].sum,
        [10, 11, 12, 13, 14, 15].sum,
        [10, 11, 12, 13, 14, 15, 16].sum,
        [10, 11, 12, 13, 14, 15, 16, 17].sum,
        [10, 11, 12, 13, 14, 15, 16, 17, 18].sum,
        [10, 11, 12, 13, 14, 15, 16, 17, 18, 19].sum,
        [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].sum,
      ]
    end

    it "should be able to get the 5 period moving average" do
      def avg(array)
        array.sum / array.length.to_f
      end

      @obj.get_column("Five Period MA").should == [
        avg([10]),
        avg([10, 11]),
        avg([10, 11, 12]),
        avg([10, 11, 12, 13]),
        avg([10, 11, 12, 13, 14]),
        avg([10, 11, 12, 13, 14, 15]),
        avg([11, 12, 13, 14, 15, 16]),
        avg([12, 13, 14, 15, 16, 17]),
        avg([13, 14, 15, 16, 17, 18]),
        avg([14, 15, 16, 17, 18, 19]),
        avg([15, 16, 17, 18, 19, 20]),
      ]
    end
  end

  context "with arguments" do
    before do
      @obj = basic_file.get_sheet("key_value_arguments")
    end

    it "should be able to evaluate a one argument kv/pair" do
      @obj.get_column("IdentityCallingOne").should == [1]
    end

    it "should be able to evaluate a list passed to the columnn/function" do
      @obj.get_column("IdentityCallingWithListOf3").should == [1, 2, 3]
    end

    it "should be able to define square" do
      @obj.get_column("SquareOf4").should == [16]
    end

    it "should be able to use two arguments" do
      @obj.get_column("TwoArgMultiply4And10").should == [40]
    end

    it "should be able to go two levels deep" do
      @obj.get_column("MySquare4TwoLevelsDeep").should == [16]
    end

    it "should be able to go two levels deep with variable shadowing" do
      @obj.get_column("MySquare4TwoLevelsDeepWithVariableShadowing").should == [16]
    end
  end
end
