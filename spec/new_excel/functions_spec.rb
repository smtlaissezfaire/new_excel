require 'spec_helper'

describe NewExcel::BuiltInFunctions do
  include NewExcel::BuiltInFunctions

  context "add" do
    it "should add two numbers" do
      add(1, 2).should == 3
    end

    it "should add many numbers" do
      add(1, 2, 3).should == 1 + 2 + 3
    end

    it "should be able to add lists of numbers together" do
      add([1, 1, 1], [2, 3, 4]).should == [1+2, 1+3, 1+4]
    end

    it "should be able to add lists of numbers to a static number" do
      add([2, 3, 4], 1000).should == [1002, 1003, 1004]
    end
  end

  context "subtract" do
    it "should be able to subtract two numbers" do
      subtract(2, 1).should == 2-1
    end

    it "should be able to subtract two vectors" do
      subtract([10, 20], [1, 2]).should == [9, 18]
    end
  end

  context "multiply" do
    it "should be able to multiply two numbers" do
      multiply(3, 4).should == 3 * 4
    end

    it "should be able to multiply multiple numbers" do
      multiply(3, 4, 10).should == 3 * 4 * 10
    end

    it "should be able to multiply vectors" do
      multiply([10, 20, 30], [1, 2, 3]).should == [10, 40, 90]
    end
  end

  context "divide" do
    it "should be able to divide two numbers" do
      divide(10, 2).should == 5
    end

    it "should not raise an error when dividing by zero" do
      lambda {
        divide(10, 0)
      }.should_not raise_error
    end
  end

  context "evaluate" do
    it "should be able to evaluate a string" do
      str = "subtract(2, 1)"
      evaluate(str).should == 2-1
    end
  end

  context "concat" do
    it "should be able to concat two strings" do
      concat("a", "b").should == "ab"
    end

    it "should be able to concat many arguments" do
      concat("a", "b", "c").should == "abc"
    end

    it "should be able to concat two lists" do
      concat(["one", "two"], [" dog", " cat"]).should == ["one dog", "two cat"]
    end
  end
end
