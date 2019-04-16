require 'spec_helper'

describe NewExcel::Data do
  def basic_file
    @file = NewExcel::File.open(File.join("spec", "fixtures", "file.ne"))
  end

  describe "with a csv map" do
    before do
      @obj = basic_file.get_sheet("original_data")
    end

    it "should be able to read the csv" do
      @obj.raw_content.should == File.read(File.join(basic_file.file_name, "original_data.csv"))
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

    it "should be able to evaluate a column" do
      @obj.evaluate("Date").should == [
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
      ]
    end

    it "should be able to get by an index (plus one)" do
      @obj.evaluate(1).should == [
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
        [ Time.parse("2019/03/01"), ],
      ]
    end

    it "should be able to evaluate two columns" do
      @obj.evaluate("Date", "Volume").should == [
        [ Time.parse("2019/03/01"), 653, ],
        [ Time.parse("2019/03/01"), 4, ],
        [ Time.parse("2019/03/01"), 404, ],
        [ Time.parse("2019/03/01"), 1021, ],
        [ Time.parse("2019/03/01"), 521, ],
        [ Time.parse("2019/03/01"), 256, ],
        [ Time.parse("2019/03/01"), 226, ],
        [ Time.parse("2019/03/01"), 938, ],
        [ Time.parse("2019/03/01"), 262 ],
      ]
    end

    it "should be able to evaluate two columns with an index" do
      @obj.evaluate(["Date", "Volume"], 1).should == [[ Time.parse("2019/03/01"), 653, ],]
      @obj.evaluate(["Date", "Volume"], 2).should == [[ Time.parse("2019/03/01"), 4, ],]
    end

    it "should be able to evaluate two columns with two indexes" do
      @obj.evaluate(["Date", "Volume"], [2, 3]).should == [[ Time.parse("2019/03/01"), 4], [Time.parse("2019/03/01"), 404]]
    end

    it "should be able to get all the rows" do
      rows = @obj.evaluate

      # @obj.evaluate.should == [
      #   [Time.parse("2019/03/01"), "0:00", "114 16.75/32", "114 17/32", "114 16.75/32", "114 16.75/32", 653, 107, 524, 129],
      #   [Time.parse("2019/03/01"), "0:05", "114 16.75/32", "114 16.75/32", "114 16.75/32", "114 16.75/32", 4, 2, 4, 0],
      #   [Time.parse("2019/03/01"), "0:10", "114 16.75/32", "114 17/32", "114 16.75/32", "114 16.75/32", 404, 85, 306, 98],
      #   [Time.parse("2019/03/01"), "0:15", "114 16.75/32", "114 16.75/32", "114 16.75/32", "114 16.75/32", 1021, 106, 314, 707],
      #   [Time.parse("2019/03/01"), "0:20", "114 16.75/32", "114 16.75/32", "114 16.75/32", "114 16.75/32", 521, 49, 296, 225],
      #   [Time.parse("2019/03/01"), "0:25", "114 17/32", "114 17/32", "114 17/32", "114 17/32", 256, 39, 50, 206],
      #   [Time.parse("2019/03/01"), "0:30", "114 16.75/32", "114 16.75/32", "114 16.75/32", "114 16.75/32", 226, 60, 175, 51],
      #   [Time.parse("2019/03/01"), "0:35", "114 16.75/32", "114 16.75/32", "114 16.5/32", "114 16.75/32", 938, 164, 338, 600],
      #   [Time.parse("2019/03/01"), "0:40", "114 16.75/32", "114 16.75/32", "114 16.75/32", "114 16.75/32", 262, 37, 3, 259],
      # ]

      rows.length.should == 9
      rows.first.length.should == 10
      rows.first[0].should be_a_kind_of(Time)
      rows.first[1].should be_a_kind_of(String)
    end

    it "should be able to read raw text even when it looks like a number" do
      @obj.evaluate("Open")[0][0].should == "114 16.75/32"
    end
  end

  context "printing" do
    it "should print" do
      @obj = basic_file.get_sheet("rows_for_printing")

      @obj.print.should == <<-CODE
One       Two        Three Four Five
--------- ---------- ---------------------
123123131 1          something really long
12        here there here there
CODE
    end
  end

  context "columns with spaces" do
    before do
      @file = NewExcel::File.open(File.join("spec", "fixtures", "file.ne"))
      @obj = basic_file.get_sheet("space_columns")
    end

    it "should have the column names trimmed" do
      @obj.columns.should == ["Date", "Time", "Open", "High", "Low", "Last", "Volume", "NumberOfTrades", "BidVolume", "AskVolume"]
    end
  end
end
