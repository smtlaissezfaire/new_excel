require 'spec_helper'

describe NewExcel::Adhoc do
  def basic_file
    @file = NewExcel::File.open(File.join("spec", "fixtures", "file.ne"))
  end

  describe "with an adhoc plain file" do
    before do
      @obj = basic_file.get_sheet("adhoc_plain")
    end

    it "should be able to get the raw content" do
      @obj.raw_content.should == File.read(File.join(basic_file.file_name, "adhoc_plain.adhoc"))
    end

    it "should be able to get the csv content" do
      @obj.parsed_content.should == [
        ['one','two','three'],
        ['four','five'],
        [],
        ['six'],
        ['seven'],
        ['eight'],
        ['nine'],
        ['10'],
        ['some long text', 'some other long text'],
      ]
    end

    it "should be able to get all of the data" do
      @obj.read.should == [
        ['one','two','three'],
        ['four','five'],
        [],
        ['six'],
        ['seven'],
        ['eight'],
        ['nine'],
        ['10'],
        ['some long text', 'some other long text'],
      ]
    end
  end

  describe "with mixed formulas" do
    before do
      @obj = basic_file.get_sheet("adhoc_simple_formula")
    end

    it "should be able to get all of the raw content" do
      @obj.raw_content.should == "number of files | = add(1, 1)\n"
    end

    it "should be able to get all of the parsed_content" do
      @obj.parsed_content.should == [
        ['number of files', '= add(1, 1)'],
      ]
    end

    it "should be able to evaluate formulas" do
      @obj.read.should == [
        ['number of files', 2],
      ]
    end
  end

  describe "with quoted data" do
    it "should parse" do
      @obj = NewExcel::Adhoc.new('tmp.txt')
      @obj.stub(:raw_content).and_return "Strong | = countif(adx.TrendStrength, \"Strong\") | = count(ohlc.DateTime) | 59.42%"
      @obj.parsed_content.should == [
        ["Strong", "= countif(adx.TrendStrength, \"Strong\")", "= count(ohlc.DateTime)", "59.42%"]
      ]
    end
  end

  describe "with an array of data" do
    before do
      @obj = basic_file.get_sheet("adhoc_array_of_data")
    end

    it "should be able to get all of the raw content" do
      @obj.raw_content.should == "array of data | = list(1, 2, 3)\n"
    end

    it "should be able to get all of the parsed_content" do
      @obj.parsed_content.should == [
        ['array of data', '= list(1, 2, 3)'],
      ]
    end

    it "should be able to evaluate formulas" do
      @obj.read.should == [
        ['array of data', '1 2 3']
      ]
    end
  end

  context "printing" do
    it "should print" do
      @obj = basic_file.get_sheet("adhoc_simple_formula")

      @obj.for_printing.should == <<-CODE
  number of files   2
CODE
    end
  end
end
