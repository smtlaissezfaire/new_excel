require "spec_helper"

describe NewExcel::Evaluator do
  before do
    @evaluator = NewExcel::Evaluator.new
    @environment = {}
  end

  it "should evaluate a primitive number as a Primitive" do
    ruby_int = 1
    ast_int = NewExcel::AST::PrimitiveInteger.new(ruby_int)

    @evaluator.evaluate(ast_int).should == ruby_int
    @evaluator.evaluate(ruby_int).should == ruby_int
  end

  it "should evaluate a primitive float as a Primitive" do
    ruby_float = 1.23
    ast_float = NewExcel::AST::PrimitiveFloat.new(ruby_float)

    @evaluator.evaluate(ast_float).should == ruby_float
    @evaluator.evaluate(ruby_float).should == ruby_float
  end

  it "should evaluate primitive booleans: true, false" do
    [true, false].each do |bool|
      ruby_boolean = bool
      ast_boolean = NewExcel::AST::Boolean.new("#{ruby_boolean}")

      @evaluator.evaluate(ast_boolean).should == ruby_boolean
      @evaluator.evaluate(ruby_boolean).should == ruby_boolean
    end
  end

  it "should be able to evaluate a string" do
    ruby_string = "test string"
    ast_string = NewExcel::AST::String.new(ruby_string)

    @evaluator.evaluate(ast_string).should == ruby_string
    @evaluator.evaluate(ruby_string).should == ruby_string
  end

  # TODO: additional types
  # TODO: checking types convert properly
  it "should evaluate a symbol in the environment"  do
    env = { x: 1 }
    symbol = NewExcel::AST::Symbol.new(:x)
    @evaluator.evaluate(symbol, env).should == 1

    env = { x: 2 }
    symbol = NewExcel::AST::Symbol.new(:x)
    @evaluator.evaluate(symbol, env).should == 2

    env = { x: 3 }
    symbol = NewExcel::AST::Symbol.new(:x)
    @evaluator.evaluate(symbol, env).should == 3
  end

  it "should evaluate a function defined in the environment by applying it" do
    env = {
      :+ => lambda {
        0
      }
    }

    symbol = NewExcel::AST::Symbol.new(:+)
    function = NewExcel::AST::FunctionCall.new(symbol)
    @evaluator.evaluate(function, env).should == 0
  end

  it "should evaluate a function defined in the environment by applying it with args" do
    env = {
      :+ => lambda { |x, y|
        x + y
      }
    }

    symbol = NewExcel::AST::Symbol.new(:+)
    int1 = NewExcel::AST::PrimitiveInteger.new(1)
    int2 = NewExcel::AST::PrimitiveInteger.new(2)

    function = NewExcel::AST::FunctionCall.new(symbol, [int1, int2])
    @evaluator.evaluate(function, env).should == 3
  end

  it "should be able to call a primitive function in array form" do
    env = {
      :+ => lambda { |x, y|
        x + y
      }
    }

    @evaluator.evaluate([:+, 1, 2], env).should == 3
  end

  it "should be able to define a function" do
    env = {}

    lambda {
      @evaluator.evaluate([:lambda, [:x, :y], [:+, :x, :y]], env)
    }.should_not raise_error
  end

  it "should be able to create an anonymous function and call it" do
    env = {
      :+ => lambda { |x, y|
        x + y
      },
    }

    res = @evaluator.evaluate([
      [:lambda, [:x, :y], [:+, :x, :y]],
      1, 2
    ],
    env)

    res.should == 3
  end

  it "should be able to define, modifying the environment" do
    env = {}

    @evaluator.evaluate([:define, :x, 1], env)
    env[:x].should == 1
  end

  it "should be able to call a defined function" do
    env = {
      :primitive_plus => lambda { |x, y|
        x + y
      }
    }

    @evaluator.evaluate(
      [:define, :+, [:lambda, [:x, :y],
        [:primitive_plus, :x, :y]]],
    env)

    res = @evaluator.evaluate([:+, 1, 2], env)
    res.should == 3
  end

  it "should be able to execute conditionally - the true expression" do
    executed_one = false
    executed_two = false

    env = {
      :one => lambda {
        executed_one = true
        1
      },
      :two => lambda {
        executed_two = true
        2
      }
    }

    res = @evaluator.evaluate(
      [:if, true,
           [:one],
           [:two]],
    env)
    res.should == 1

    executed_one.should == true
    executed_two.should == false
  end

  it "should be able to execute conditionally - the false expression" do
    executed_one = false
    executed_two = false

    env = {
      :one => lambda {
        executed_one = true
        1
      },
      :two => lambda {
        executed_two = true
        2
      }
    }

    res = @evaluator.evaluate(
      [:if, false,
           [:one],
           [:two]],
    env)
    res.should == 2

    executed_one.should == false
    executed_two.should == true
  end

  it "should evaluate a function from the ast" do
    env = {
      :primitive_plus => lambda { |x, y|
        x + y
      }
    }

    function_call = NewExcel::AST::FunctionCall.new(
      NewExcel::AST::Symbol.new(:primitive_plus),
      [
        NewExcel::AST::PrimitiveInteger.new(1),
        NewExcel::AST::PrimitiveInteger.new(2),
      ]
    )

    ast = NewExcel::AST::Function.new([:x, :y], [
      function_call
    ])

    @evaluator.evaluate([
      [:define, :+, ast],
    ], env)

    @evaluator.evaluate([:+, 1, 2], env).should == 3
  end

  it "should define a key value pair as a define" do
    env = {}

    key = NewExcel::AST::Symbol.new(:x)
    value = NewExcel::AST::PrimitiveInteger.new(1)

    kv_pair = NewExcel::AST::KeyValuePair.new(key, value)

    @evaluator.evaluate(kv_pair, env)
    env[:x].should == 1
  end

  it "should define a key value pair as a define with the right key + value" do
    env = {}

    key = NewExcel::AST::Symbol.new(:y)
    value = NewExcel::AST::PrimitiveInteger.new(2)

    kv_pair = NewExcel::AST::KeyValuePair.new(key, value)

    @evaluator.evaluate(kv_pair, env)
    env[:y].should == 2
  end

  it "should be able to quote a symbol" do
    @evaluator.evaluate([:quote, :foo]).should == :foo
    @evaluator.evaluate([:quote, NewExcel::AST::Symbol.new(:bar)]).should == :bar
  end

  it "should be able to quote a list without evaluating" do
    @evaluator.evaluate([:quote, [1, 2, 3]]).should == [1,2,3]

    function_call = NewExcel::AST::FunctionCall.new(
      NewExcel::AST::Symbol.new(:primitive_plus),
      [
        NewExcel::AST::PrimitiveInteger.new(1),
        NewExcel::AST::PrimitiveInteger.new(2),
      ]
    )

    ast = NewExcel::AST::Function.new([:x, :y], [
      function_call
    ])

    @evaluator.evaluate([:quote, ast], {}).should == [:lambda, [:x, :y], [:primitive_plus, 1, 2]]
  end

  it "should be able to quote various types of primitives" do
    # Integer, Float, TrueClass, FalseClass, String
    @evaluator.evaluate([:quote, 1]).should == 1
    @evaluator.evaluate([:quote, 1.23]).should == 1.23
    @evaluator.evaluate([:quote, true]).should == true
    @evaluator.evaluate([:quote, false]).should == false
    @evaluator.evaluate([:quote, "foo"]).should == "foo"
  end

  it "should quote foo.bar syntax as a lookup of foo in the bar environment" do
    file_reference = NewExcel::AST::Symbol.new(:file)
    column_reference = NewExcel::AST::Symbol.new(:column)

    ast = NewExcel::AST::FileReference.new(file_reference, column_reference)

    @evaluator.evaluate([:quote, ast]).should == [:lookup_cell, :column, :file] # Change me?
  end

  it "should be able to evaluate a map with the right hash_map" do
    ast = NewExcel::AST::Map.new(foo: 1)

    @evaluator.evaluate([:quote, ast]).should == { foo: 1 }
    @evaluator.evaluate(foo: 1).should == { foo: 1 }
    @evaluator.evaluate(ast).should == { foo: 1 }
  end
end
