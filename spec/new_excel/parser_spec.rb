require 'spec_helper'

describe NewExcel::Parser do
  before do
    @obj = NewExcel::Parser.new
  end

  context "primitives" do
    it "should be able to parse a string" do
      @obj.parse("string").should == "string"
    end

    it "should parse an integer" do
      @obj.parse("123").should == 123
    end

    it "should parse a floating point" do
      @obj.parse("123.456").should == 123.456
    end

    it "should parse a Date" do
      @obj.parse("2018-01-01").should == Time.parse("2018-01-01 00:00:00")
    end

    it "should parse a Time" do # FIXME?
      @obj.parse("11:00").should == "11:00"
    end

    it "should parse a DateTime" do
      @obj.parse("2018-01-01 11:00:00").should == Time.parse("2018-01-01 11:00:00")
    end

    it "should be able to parse a date with slahes" do
      @obj.parse("2019/03/01").should == Time.parse("2019-03-01 00:00:00")
    end
  end
end
