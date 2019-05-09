require 'spec_helper'

describe NewExcel::BuiltInFunctions do
  include NewExcel::BuiltInFunctions

  def parse_eval(str)
    evaluate(parse(str))
  end

  context "add" do
    it "should add two numbers" do
      parse_eval("add(1, 2)").should == 3
    end

    it "should add many numbers" do
      parse_eval("add(1, 2, 3)").should == 1 + 2 + 3
    end

    it "should be able to add a list of numbers" do
      fold("add", [1, 2, 3]).should == 6
    end

    it "should be able to add columns of numbers" do
      parse_eval("add(list(1, 2, 3), list(4, 5, 6))").should == [1+4, 2+5, 3+6]
    end

    it "should be able to add 3 columns of numbers" do
      parse_eval("add(list(1, 2, 3), list(4, 5, 6), list(7, 8, 9))").should == [1+4+7, 2+5+8, 3+6+9]
    end

    it "should be able to add two lists of numbers" do
      parse_eval("add(list(1, 2, 3), list(4, 5, 6))").should == [1+4, 2+5, 3+6]
    end
  end

  context "subtract" do
    it "should be able to subtract two numbers" do
      parse_eval("subtract(2, 1)").should == 2-1
    end

    it "should be able to subtract two vectors" do
      parse_eval("subtract(list(10, 20), list(1, 2))").should == [9, 18]
    end

    it "should be able to subtract three numbers" do
      parse_eval("subtract(10, 3, 1)").should == 10 - 3 - 1
    end
  end

  context "multiply" do
    it "should be able to multiply two numbers" do
      parse_eval("multiply(3, 4)").should == 3 * 4
    end

    it "should be able to multiply multiple numbers" do
      parse_eval("multiply(3, 4, 10)").should == 3 * 4 * 10
    end

    it "should be able to multiply vectors" do
      parse_eval("multiply(list(10, 20, 30), list(1, 2, 3))").should == [10, 40, 90]
    end

    it "should be able to multiply a vector by a number" do
      parse_eval("multiply(list(1, 2, 3), 2)").should == [2, 4, 6]
    end
  end

  context "divide" do
    it "should be able to divide two numbers" do
      parse_eval("divide(10, 2)").should == 5
    end

    it "should not raise an error when dividing by zero" do
      lambda {
        parse_eval("divide(10, 0)")
      }.should_not raise_error
    end

    it "should work with decimals" do
      parse_eval("divide(1, 2)").should == 0.5
    end

    it "should work with two lists" do
      parse_eval("divide(list(10, 20), list(10, 30))").should == [1, 2/3.to_f]
    end

    it "should work with a list and one number" do
      parse_eval("divide(list(0.015625, 0.0078125), 0.0078125)").should == [2, 1]
    end

  end

  context "square" do
    it "should be able to square a number" do
      parse_eval("square(1)").should == 1
      parse_eval("square(2)").should == 4
      parse_eval("square(3)").should == 9
    end

    it "should be able to square a list of numbers" do
      parse_eval("square(list(1, 2, 3))").should == [1, 4, 9]
    end
  end

  context "concat" do
    it "should be able to concat two strings" do
      parse_eval('concat("a", "b")').should == "ab"
    end

    it "should be able to concat many arguments" do
      parse_eval('concat("a", "b", "c")').should == "abc"
    end

    it "should be able to concat two lists" do
      parse_eval('concat(list("one", "two"), list(" dog", " cat"))').should == ["one dog", "two cat"]
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
      parse_eval("average(1, 2, 3)").should == 2
    end

    it "should work with floats" do
      parse_eval("average(1, 4)").should == 2.5
    end
  end

  context "apply" do
    it "should be able to apply a function to a list" do
      apply("add", [1, 2, 3]).should == 1+2+3
    end
  end

  context "index" do
    it "should be able to get an index of a list" do
      index([10, 20, 30]).should == [1, 2, 3]
      index([1, 2]).should == [1,2]
    end

    it "should be able to indexes based on bounds" do
      index(range(10, 50), 1, 2).should == [10, 11]
    end

    it "should be able to indexes everything up until current index" do
      index(range(10, 50), nil, 3).should == [10, 11, 12]
    end

    it "should be able to index with a specific integer" do
      index([10, 20, 30], 2).should == 20
    end
  end

  context "each" do
    it "should yield a list of lists" do
      each([10, 20, 30]).should == [
        [10],
        [10, 20],
        [10, 20, 30],
      ]
    end

    it "should be able to sum the first result of an each call" do
      each_call = each([10, 20, 30])

      first_val = each_call.first
      first_val.should == [10]

      second_val = each_call[1]
      second_val.should == [10, 20]

      fold("sum", first_val).should == 10
      fold("sum", second_val).should == 30
    end

    it "should be able to sum" do
      each_values = each([1,2,3,4])

      each_values.should == [
        [1],
        [1, 2],
        [1, 2, 3],
        [1, 2, 3, 4],
      ]

      map("sum", each_values).should == [
        1,
        1+2,
        1+2+3,
        1+2+3+4,
      ]
    end

    it "should be able to map the sums of an each call" do
      each_call = each([10, 20, 30])

      map("sum", each_call).should == [
        10,
        10+20,
        10+20+30,
      ]
    end
  end

  context "abs" do
    it "should work on simple numbers" do
      abs(1).should == 1
      abs(-1).should == 1
      abs(-12.2342342).should == 12.2342342
    end

    it "should work on a list of numbers" do
      abs([1, -1, 10, -10]).should == [1, 1, 10, 10]
    end
  end

  context "max" do
    it "should find the max of two numbers" do
      max(1, 2).should == 2
      max(100, 2).should == 100
    end

    it "should work on a list" do
      fold("max", [1, 2, 3]).should == 3
    end

    it "should work on multiple lists" do
      max(
        [1, 2, 3],
        [10, 20, 0.10],
        [50, 0, 3.11],
      ).should == [50, 20, 3.11]
    end
  end

  context "min" do
    it "should find the min of two numbers" do
      min(1, 2).should == 1
      min(100, 2).should == 2
    end

    it "should work on a list" do
      fold("min", [1, 2, 3]).should == 1
    end

    it "should work on multiple lists" do
      min(
        [1, 2, 3],
        [10, 20, 0.10],
        [50, 0, 3.11],
      ).should == [1, 0, 0.10]
    end

    it "should be able to get the results of multiple columns" do
      col1 = [ 10, 20, 30, 40 ]
      col2 = [ 11, 21, 31, 1 ]
      col3 = [  9, 21, 40, 2 ]

      min(col1, col2, col3).should == [9, 20, 30, 1]
    end

    it "should be able to lookback to get the results of multiple columns" do
      col1 = [ 10, 20, 30, 40 ]
      col2 = [ 11, 21, 31, 1 ]
      col3 = [  9, 21, 40, 2 ]

      lookback(each(min(col1, col2, col3)), 2).should == [
        [9],
        [9, 20],
        [9, 20, 30],
        [20, 30, 1],
      ]
    end

    it "should be able to get the min of the lookbacks" do
      col1 = [ 10, 20, 30, 40 ]
      col2 = [ 11, 21, 31, 1 ]
      col3 = [  9, 21, 40, 2 ]

      map("min", lookback(each(min(col1, col2, col3)), 2)).should == [
        [9].min,
        [9, 20].min,
        [9, 20, 30].min,
        [20, 30, 1].min,
      ]
    end
  end

  context "flatten" do
    it "should flatten any list" do
      flatten([[[[1]]]]).should == [1]
    end
  end

  context "eq" do
    it "should return true if both are boolean true" do
      eq(true, true).should == true
    end

    it "should return true if both are boolean false" do
      eq(false, false).should == true
    end

    it "should return false if one is true, one is false" do
      eq(true, false).should == false
    end

    it "should return false if one is true, one is false" do
      eq(false, true).should == false
    end

    it "should work with lists" do
      eq([1, 2, 3], [1, 3, 2]).should == [true, false, false]
    end

    it "should work with multiple lists" do
      eq([1, 2, 3], [1, 3, 2], [0, 1, 1]).should == [false, false, false]
    end
  end

  context "gt" do
    it "should be true for 5 > 2" do
      gt(5, 2).should == true
    end

    it "should be false for 2 > 5" do
      gt(2, 5).should == false
    end

    it "should be false for 2 > 2" do
      gt(2, 2).should == false
    end

    it "should work with lists" do
      gt([12, 5], [1, 17]).should == [true, false]
    end
  end

  context "gte" do
    it "should be true for 5 > 2" do
      gte(5, 2).should == true
    end

    it "should be false for 2 > 5" do
      gte(2, 5).should == false
    end

    it "should be true for 2 > 2" do
      gte(2, 2).should == true
    end

    it "should work with lists" do
      gte([12, 5], [1, 17]).should == [true, false]
    end

    it "should work with one list and one number" do
      gte([12, 5], 6).should == [true, false]
    end
  end

  context "lte" do
    it "should be false for 5 < 2" do
      lte(5, 2).should == false
    end

    it "should be true for 2 > 5" do
      lte(2, 5).should == true
    end

    it "should be true for 2 < 2" do
      lte(2, 2).should == true
    end

    it "should work with lists" do
      lte([12, 5], [1, 17]).should == [false, true]
    end
  end

  context "lt" do
    it "should be false for 5 < 2" do
      lte(5, 2).should == false
    end

    it "should be true for 2 > 5" do
      lte(2, 5).should == true
    end

    it "should be false for 2 < 2" do
      lt(2, 2).should == false
    end

    it "should work with lists" do
      lte([12, 5], [1, 17]).should == [false, true]
    end
  end

  context "hour" do
    it "should return the hour of a datetime" do
      t = Time.parse("2019-01-01 2:05PM")
      hour(t).should == 12 + 2
    end

    it "should work with arrays" do
      t1 = Time.parse("2019-01-01 2:05PM")
      t2 = Time.parse("2019-01-01 3:05PM")

      hour([t1, t2]).should == [14, 15]
    end
  end

  context "time" do
    it "should parse a time" do
      time("10AM").hour.should == 10
    end

    it "should parse a list of times" do
      time(["10AM", "11AM"]).map(&:hour).should == [10, 11]
    end
  end

  context "any?" do
    it "should be true if any are true" do
      any?(true, false).should == true
    end

    it "should be false if all are false" do
      any?(false, false).should == false
    end

    it "should work with two lists" do
      any?([true, false, false], [false, false, true]).should == [true, false, true]
    end
  end

  context "and" do
    it "should be true if both are true" do
      parse_eval('and(true, true)').should == true
    end

    it "should be false if the first is false" do
      parse_eval('and(false, true)').should == false
    end

    it "should be false if the last is false" do
      parse_eval('and(true, false)').should == false
    end

    it "should be able to use two lists" do
      parse_eval('and(list(true, true), list(true, false))').should == [true, false]
    end

    it "should take multiple arguments" do
      parse_eval('and(true, true, true)').should == true
      parse_eval('and(true, false, true)').should == false
      parse_eval('and(false, false, true)').should == false
    end

    it "should take lists of arguments" do
      parse_eval('and(list(true, true, true), list(true, false, false))').should == [true, false, false]
      parse_eval('and(list(true, false, true), list(true, false, false))').should == [true, false, false]
      parse_eval('and(list(false, false, true), list(true, false, false))').should == [false, false, false]
    end

    it "should not evaluate the second argument if the first argument is false" do
      parse_eval('and(false, RAISE_GOT_HERE)').should == false
    end
  end

  context "if" do
    it "should return the first value if true" do
      parse_eval("if(true, 1, 2)").should == 1
    end

    it "should return the second value if false" do
      parse_eval("if(false, 1, 2)").should == 2
    end

    it "should evaluate the first argument if true" do
      parse_eval("if(true, eq(true, true), false)").should == true
    end

    it "should evaluate the second argument if true" do
      parse_eval("if(false, 1, eq(2, 2))").should == true
    end

    it "should not eval the first argument if false" do
      parse_eval("if(false, BLAHBLAH, eq(2, 2))").should == true
    end

    it "should not eval the second argument if true" do
      parse_eval("if(true, true, BLAHBLAH)").should == true
    end

    it "should work with lists" do
      parse_eval("if(list(true, false), list(1, 2), list(3, 4))").should == [1, 4]
    end

    it "should work with single values that get evaluated" do
      parse_eval("if(evaluate(true), 1, 0)").should == 1
    end

    it "should return a single value in the true branch if only one given (but a list given in the conditions)" do
      parse_eval("if(list(true, true), true, false)").should == [true, true]
    end

    it "should return a single value in the true branch if only one given (but a list given in the conditions)" do
      parse_eval("if(list(false, false), true, false)").should == [false, false]
    end
  end

  context "not" do
    it "should make a true value false" do
      parse_eval('not(true)').should == false
    end

    it "should make a false value true" do
      parse_eval('not(false)').should == true
    end

    it "should work with a list" do
      parse_eval("not(list(true, false))").should == [false, true]
    end
  end
end
