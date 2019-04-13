require 'spec_helper'

describe NewExcel::File do
  context "basic operation" do
    include FakeFS::SpecHelpers
    include NewExcel

    it "should be able to initialize with no arguments" do
      lambda {
        NewExcel::File.new
      }.should_not raise_error
    end

    it "should have a list of zero sheets" do
      f = NewExcel::File.new
      f.sheets.should == []
      f.sheet_names.should == []
    end

    it "should be able to read a file" do
      Dir.mkdir("tmp.ne")

      f = NewExcel::File.open("tmp.ne")
      f.sheets.should == []
      f.sheet_names.should == []
    end

    it "should raise if the file doesn't exist" do
      lambda {
        ::NewExcel::File.open("tmp.ne")
      }.should raise_error(Errno::ENOENT)
    end

    def make_sheet_file!
      Dir.mkdir("tmp.ne")
    end

    def make_sheet_file_with_contents!
      make_sheet_file!
      FileUtils.touch("tmp.ne/example.map")
      FileUtils.touch("tmp.ne/data.csv")
    end

    it "should have the filename" do
      make_sheet_file!

      f = ::NewExcel::File.open("tmp.ne")
      f.file_name.should == "tmp.ne"
    end

    it "should have no sheets initially" do
      make_sheet_file!

      f = ::NewExcel::File.open("tmp.ne")
      f.sheets.should == []
      f.sheet_names.should == []
    end

    it "should list the sheets" do
      make_sheet_file_with_contents!

      f = ::NewExcel::File.open("tmp.ne")
      f.sheet_names.should include("example", "data")
    end

    it "should be able to load a sheet" do
      make_sheet_file_with_contents!

      f = ::NewExcel::File.open("tmp.ne")
      f.load_sheet("example")
      f.loaded_sheets.should include("example")
    end

    it "should be able to get a sheet (and load it with the map type)" do
      make_sheet_file_with_contents!

      f = ::NewExcel::File.open("tmp.ne")
      sheet = f.get_sheet("example")
      sheet.should be_a(NewExcel::Map)
    end

    it "should be able to get a sheet (and load it with the data type)" do
      make_sheet_file_with_contents!

      f = ::NewExcel::File.open("tmp.ne")
      sheet = f.get_sheet("data")
      sheet.should be_a(NewExcel::Data)
    end
  end
end
