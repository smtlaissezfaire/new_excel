require 'spec_helper'

describe NewExcel::ProcessState do
  before do
    @state = NewExcel::ProcessState
  end

  context "max_rows_to_load" do
    before do
      @file = NewExcel::File.open("spec/fixtures/file.ne")
      @sheet = @file.get_sheet("original_data")
    end

    it "should be nil initially" do
      @state.max_rows_to_load.should be_nil
    end

    it "should load all the rows when it isn't set" do
      @state.max_rows_to_load = nil
      @sheet.evaluate.length.should == 9
    end

    it "should load the max specified" do
      @state.max_rows_to_load = 5
      @sheet.evaluate.length.should == 5
    end

    it "should NOT refresh when the value is refeshed (feature? bug?)" do
      @state.max_rows_to_load = 1000
      @sheet.evaluate.length.should == 9

      @state.max_rows_to_load = 2
      @sheet.evaluate.length.should == 9

      @state.max_rows_to_load = 5
      @sheet.evaluate.length.should == 9
    end
  end
end
