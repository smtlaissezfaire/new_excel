require 'spec_helper'

describe NewExcel::Data do
  describe "with a csv map" do
    before do
      @file = File.join("spec", "fixtures", "file.ne", "original_data.csv")
      @obj = NewExcel::Data.new(@file)
    end

    it "should be able to read a map" do
      @obj.raw_content.should == File.read(@file)
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
      # rows.first[2].should be_a_kind_of(String)
    end
  end

  context "printing" do
    it "should print" do
      @file = File.join("spec", "fixtures", "file.ne", "rows_for_printing.csv")
      @obj = NewExcel::Data.new(@file)

      @obj.print.should == <<-CODE
One       Two        Three Four Five
--------- ---------- ---------------------
123123131 1          something really long
12        here there here there
CODE
    end
  end
end
