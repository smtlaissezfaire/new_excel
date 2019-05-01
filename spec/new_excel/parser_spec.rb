require 'spec_helper'

describe NewExcel::Parser do
  before do
    @obj = NewExcel::Parser.new
  end

  def parse(str)
    @obj.parse(str)
  end

  def parse_statement(str)
    obj = parse(str)

    if obj
      obj.declarations.first
    else
      raise "Couldn't parse str: #{str}"
    end
  end

  def parse_map(str)
    obj = parse(str)

    if obj
      obj.map
    else
      raise "Couldn't parse str: #{str}"
    end
  end

  context "functions" do
    it "should be able to parse a function" do
      res = parse_statement("= add()")
      res.should be_a_kind_of(NewExcel::AST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == :add
      body.arguments.should == []
    end

    it "should be able to parse functions with question marks" do
      res = parse_statement("= any?(true, false)")
      res.should be_a_kind_of(NewExcel::AST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == :any?
    end

    it "should be able to parse a function with an argument" do
      res = parse_statement("=add(1)")
      res.should be_a_kind_of(NewExcel::AST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == :add
      body.arguments.length.should == 1
      arg = body.arguments.first

      arg.should be_a_kind_of(NewExcel::AST::PrimitiveInteger)
      arg.string.should == "1"
      arg.value.should == 1
    end

    it "should be able to parse a function with multiple arguments" do
      res = parse_statement("=add(1, 2, 3)")
      res.should be_a_kind_of(NewExcel::AST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == :add
      body.arguments.length.should == 3

      body.arguments[0].should be_a_kind_of(NewExcel::AST::PrimitiveInteger)
      body.arguments[0].string.should == "1"
      body.arguments[0].value.should == 1

      body.arguments[1].should be_a_kind_of(NewExcel::AST::PrimitiveInteger)
      body.arguments[1].string.should == "2"
      body.arguments[1].value.should == 2

      body.arguments[2].should be_a_kind_of(NewExcel::AST::PrimitiveInteger)
      body.arguments[2].string.should == "3"
      body.arguments[2].value.should == 3
    end

    it "should be able to evaluate the function" do
      ast = parse_statement("add(1, 2)")
      evaluator = NewExcel::Evaluator.new

      env = NewExcel::Runtime.base_environment

      evaluator.evaluate(ast, env).should == 3
    end

    it "should parse remote cell references" do
      str = "= other_sheet.other_column"

      NewExcel::Tokenizer.get_tokens(str).should == [
        [:EQ, "="],
        [:ID, "other_sheet"],
        [:DOT, "."],
        [:ID, "other_column"],
        [false, false],
      ]

      res = parse_statement("= other_sheet.other_column")
      res.should be_a_kind_of(NewExcel::AST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::AST::FileReference)
      body.file_reference.should == :other_sheet
      body.symbol.should == :other_column
    end

    it "should be able to evaluate a remote cell reference" do
      str = "= other_sheet.other_column"

      NewExcel::Tokenizer.get_tokens(str).should == [
        [:EQ, "="],
        [:ID, "other_sheet"],
        [:DOT, "."],
        [:ID, "other_column"],
        [false, false],
      ]

      res = parse_statement("= other_sheet.other_column")

      res.should be_a_kind_of(NewExcel::AST::Function)
      body = res.body[0]
      body.should be_a_kind_of(NewExcel::AST::FileReference)
      body.file_reference.should == :other_sheet
      body.symbol.should == :other_column
    end

    it "should be able to evaluate a local cell reference" do
      str = "= other_column"

      NewExcel::Tokenizer.get_tokens(str).should == [
        [:EQ, "="],
        [:ID, "other_column"],
        [false, false],
      ]

      res = parse_statement("= other_column")

      res.should be_a_kind_of(NewExcel::AST::Function)
      body = res.body[0]
      body.should be_a_kind_of(NewExcel::AST::Symbol)
      body.symbol.should == :other_column
    end

    it "should allow strings passed to arguments" do
      str = "= trim(\" foo \")"

      res = parse_statement(str)
      res.should be_a_kind_of(NewExcel::AST::Function)
      body = res.body[0]
      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.arguments.length.should == 1

      arg = body.arguments[0]
      arg.should be_a_kind_of(NewExcel::AST::String)
      arg.value.should == " foo "
    end

    it "should be able to parse a Map" do
      str = <<-CODE
One:
  1
CODE

      res = parse_map(str)
      res.should be_a_kind_of(NewExcel::AST::Map)
      res.to_hash.keys.should == [:One]
      res.to_hash[:One].value.should == 1
    end

    it "should be able to parse a known file" do
      str = File.read("spec/fixtures/file.ne/simple_text.map")

      # NewExcel::Tokenizer.get_tokens(str).should == []

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::AST::StatementList)
      res.map.should be_a_kind_of(NewExcel::AST::Map)
    end

    it "should be able to parse a function that calls another column" do
      str = File.read("spec/fixtures/file.ne/function_on_column.map")

      res = parse_map(str)
      res.should be_a_kind_of(NewExcel::AST::Map)
      res.to_hash.keys.should == [:String1, :String2]

      string_2_value = res.to_hash[:String2]
      string_2_value.should_not be_nil
      string_2_value.should be_a(NewExcel::AST::Function)

      string_2_value.body[0].should be_a_kind_of(NewExcel::AST::FunctionCall)
      string_2_value.body[0].arguments[0].should be_a(NewExcel::AST::Symbol)
    end

    it "should be able to call a one letter function " do
      res = parse_statement "= c()"
      res.should be_a_kind_of(NewExcel::AST::Function)
      res.body[0].should be_a_kind_of(NewExcel::AST::FunctionCall)
    end

    it "should be able to define a one character key" do
      str = "X: 1"

      res = parse_map(str)

      res.should be_a_kind_of(NewExcel::AST::Map)
      res.to_hash.keys.should == [:X]
    end
  end

  context "primitives - evaluating" do
    it "should be able to parse text" do
      parse_statement("\"string\"").value.should == "string"
    end

    it "should parse an integer" do
      parse_statement("123").value.should == 123
    end

    it "should parse a floating point" do
      parse_statement("123.456").value.should == 123.456
    end

    it "should parse a negative number" do
      parse_statement("-123").value.should == -123
    end

    it "should parse true as true" do
      parse_statement("true").value.should == true
    end

    it "should parse false as false" do
      parse_statement("false").value.should == false
    end
  end

  context "Functions" do
    it "should parse a function with an equal sign" do
      parse_statement("= 1").should be_a_kind_of(NewExcel::AST::Function)
    end

    it "should parse a function with an equal sign as having zero arguments" do
      val = parse_statement("= 1")
      val.should be_a_kind_of(NewExcel::AST::Function)
      val.formal_arguments.should == []
    end

    it "should parse a function with an empty argument list and an an equal sign as having zero arguments" do
      str = "() = 1"

      NewExcel::Tokenizer.get_tokens(str).should == [
        [:OPEN_PAREN, "("],
        [:CLOSE_PAREN, ")"],
        [:EQ, "="],
        [:INTEGER, "1"],
        [false, false],
      ]

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::Function)
      val.formal_arguments.should == []
    end

    it "should parse a function with an argument" do
      str = "(x) = 1"

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::Function)
      val.formal_arguments.length.should == 1
      val.formal_arguments[0].should be_a_kind_of(NewExcel::AST::Symbol)
      val.formal_arguments[0].symbol.should == :x
    end

    it "should parse multiple function arguments" do
      str = "(x, y) = 1"

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::Function)
      val.formal_arguments.length.should == 2
      val.formal_arguments[0].should be_a_kind_of(NewExcel::AST::Symbol)
      val.formal_arguments[0].symbol.should == :x
      val.formal_arguments[1].should be_a_kind_of(NewExcel::AST::Symbol)
      val.formal_arguments[1].symbol.should == :y
    end
  end

  describe "misc function parsing" do
    it "should be able to parse a map with a function" do
      # lambda((x) add(x, 1))
      str = "plus: (x, y) = +(x, y)"

      val = parse_map(str)
      val.should be_a_kind_of(NewExcel::AST::Map)
    end

    it "should be able to set a simple function" do
      str = "foo := 1"
      val = parse_map(str)
      val.should be_a_kind_of(NewExcel::AST::Map)
      val.to_hash.keys.should include(:foo)
      val.to_hash[:foo].should be_a_kind_of(NewExcel::AST::Function)
    end

    it "should be able to parse a define" do
      str = "define(one, 1)"

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::FunctionCall)
    end

    it "should be able to pass a function as an anonymous function as an argument" do
      str = "define(one, = 1)"

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::FunctionCall)
    end

    it "should be able to pass a function as an anonymous function with params as an argument" do
      str = "define(one, (x) = 1)"

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::FunctionCall)
    end

    it "should be able to wrap an annonymous function in parens and call it (part 2)" do
      str = "(= 1)()"

      NewExcel::Tokenizer.tokenize(str).should == [
        [:OPEN_PAREN, "("],
        [:EQ, "="],
        [:INTEGER, "1"],
        [:CLOSE_PAREN, ")"],
        [:OPEN_PAREN, "("],
        [:CLOSE_PAREN, ")"],
        [false, false]
      ]

      val = parse_statement(str)
      val.should be_a_kind_of(NewExcel::AST::FunctionCall)
    end

  end
end
