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
      pending "FIXME"
      add([1, 1, 1], [2, 3, 4]).should == [1+2, 1+3, 1+4]
    end

    it "should be able to add lists of numbers to a static number" do
      pending "FIXME"
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

    it "should be able to subtract three numbers" do
      subtract(10, 3, 1).should == 10 - 3 - 1
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

    it "should be able to multiply a vector by a number" do
      multiply([1, 2, 3], 2).should == [2, 4, 6]
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

    it "should work with decimals" do
      divide(1, 2).should == 0.5
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

  context "left" do
    it "should return the number of characters specified" do
      left("Google Sheets", 2).should == "Go"
    end

    it "should work on a vectors" do
      left(["One", "Two"], [1, 2]).should == ["O", "Tw"]
    end

    it "should work with two vectors and a number" do
      left(["One", "Two"], 2).should == ["On", "Tw"]
    end
  end

  context "mid" do
    it "should return the middle" do
      mid("get this", 5, 4).should == "this"
    end

    it "should be able to work in an array context" do
      mid(["get this", "get that"], 5, 4).should == ["this", "that"]
    end
  end

  context "right" do
    it "should extract from the right" do
      right("Google Sheets", 2).should == "ts"
    end

    it "should work with lists" do
      right(["Hello", "World"], 1).should == ["o", "d"]
    end
  end

  context "search" do
    it "should find the index (+1, of course) of the search" do
      search("def", "abcdefg").should == 4
    end

    it "should search starting an an index" do
      search("def", "abcdefgdefg", 6).should == 8
    end

    it "should work with arrays" do
      search("def", ["abcdef", "abcxyzdef"]).should == [4, 7]
    end
  end

  context "join" do
    it "should return the arguments joined as a string" do
      join(1, 2, 3).should == "1 2 3"
    end

    it "should arrays joined" do
      join([1, 2, 3], ["a", "b"]).should == ["1 a", "2 b", "3"]
    end

    it "should not trim arguments" do
      join("   a", "   b ").should == "   a    b "
    end
  end

  context "list" do
    it "should return an array of values" do
      list(1, 2, 3).should == [1, 2, 3]
    end
  end

  context "value" do
    it "should get a string as an integer" do
      value("1").should == 1
    end

    it "should get a string as an float when containing a decimal" do
      value("1.23").should == 1.23
    end

    it "should keep an int the same" do
      value(1).should == 1
    end

    it "should keep a float the same" do
      value(1.23).should == 1.23
    end

    it "should be able to handle arrays of stuff" do
      value(["1", "2"]).should == [1, 2]
    end
  end

  context "range" do
    it "should create an array" do
      range(1, 10).should == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    end

    it "should be able to take multiple lists" do
      range([1, 10], [2, 15]).should == [[1, 2], [10, 11, 12, 13, 14, 15]]
    end
  end

  context "average" do
    it "should work with a simple list" do
      average([1, 2, 3]).should == 2
    end

    it "should work with floats" do
      average([1, 4]).should == 2.5
    end
  end
end
