require 'spec_helper'

describe NewExcel::NewParser do
  before do
    @obj = NewExcel::NewParser.new
  end

  context "functions" do
    it "should be able to parse a function" do
      res = @obj.parse("= add()")
      res.should be_a_kind_of(NewExcel::NewAST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::NewAST::FunctionCall)
      body.name.should == :add
      body.arguments.should == []
    end

    it "should be able to parse functions with question marks" do
      res = @obj.parse("= any?(true, false)")
      res.should be_a_kind_of(NewExcel::NewAST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::NewAST::FunctionCall)
      body.name.should == :any?
    end

    it "should be able to parse a function with an argument" do
      res = @obj.parse("=add(1)")
      res.should be_a_kind_of(NewExcel::NewAST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::NewAST::FunctionCall)
      body.name.should == :add
      body.arguments.length.should == 1
      arg = body.arguments.first

      arg.should be_a_kind_of(NewExcel::NewAST::PrimitiveInteger)
      arg.string.should == "1"
      arg.value.should == 1
    end

    it "should be able to parse a function with multiple arguments" do
      res = @obj.parse("=add(1, 2, 3)")
      res.should be_a_kind_of(NewExcel::NewAST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::NewAST::FunctionCall)
      body.name.should == :add
      body.arguments.length.should == 3

      body.arguments[0].should be_a_kind_of(NewExcel::NewAST::PrimitiveInteger)
      body.arguments[0].string.should == "1"
      body.arguments[0].value.should == 1

      body.arguments[1].should be_a_kind_of(NewExcel::NewAST::PrimitiveInteger)
      body.arguments[1].string.should == "2"
      body.arguments[1].value.should == 2

      body.arguments[2].should be_a_kind_of(NewExcel::NewAST::PrimitiveInteger)
      body.arguments[2].string.should == "3"
      body.arguments[2].value.should == 3
    end

    it "should be able to evaluate the function" do
      ast = @obj.parse("add(1, 2)")
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

      res = @obj.parse("= other_sheet.other_column")
      res.should be_a_kind_of(NewExcel::NewAST::Function)

      body = res.body[0]

      body.should be_a_kind_of(NewExcel::NewAST::FileReference)
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

      res = @obj.parse("= other_sheet.other_column")

      res.should be_a_kind_of(NewExcel::NewAST::Function)
      body = res.body[0]
      body.should be_a_kind_of(NewExcel::NewAST::FileReference)
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

      res = @obj.parse("= other_column")

      res.should be_a_kind_of(NewExcel::NewAST::Function)
      body = res.body[0]
      body.should be_a_kind_of(NewExcel::NewAST::Symbol)
      body.symbol.should == :other_column
    end

    it "should allow strings passed to arguments" do
      str = "= trim(\" foo \")"

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::NewAST::Function)
      body = res.body[0]
      body.should be_a_kind_of(NewExcel::NewAST::FunctionCall)
      body.arguments.length.should == 1

      arg = body.arguments[0]
      arg.should be_a_kind_of(NewExcel::NewAST::String)
      arg.value.should == " foo "
    end

    it "should be able to parse a Map" do
      str = <<-CODE
One:
  1
CODE

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::NewAST::Map)
      res.to_hash.keys.should == [:One]
      res.to_hash[:One].value.should == 1
    end

    it "should be able to parse a known file" do
      str = File.read("spec/fixtures/file.ne/simple_text.map")

      # NewExcel::Tokenizer.get_tokens(str).should == []

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::NewAST::Map)
    end

    it "should be able to parse a function that calls another column" do
      str = File.read("spec/fixtures/file.ne/function_on_column.map")

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::NewAST::Map)
      res.to_hash.keys.should == [:String1, :String2]

      string_2_value = res.to_hash[:String2]
      string_2_value.should_not be_nil
      string_2_value.should be_a(NewExcel::NewAST::Function)

      string_2_value.body[0].should be_a_kind_of(NewExcel::NewAST::FunctionCall)
      string_2_value.body[0].arguments[0].should be_a(NewExcel::NewAST::Symbol)
    end

    it "should be able to call a one letter function " do
      res = @obj.parse "= c()"
      res.should be_a_kind_of(NewExcel::NewAST::Function)
      res.body[0].should be_a_kind_of(NewExcel::NewAST::FunctionCall)
    end

    it "should be able to define a one character key" do
      str = "X: 1"

      res = @obj.parse(str)

      res.should be_a_kind_of(NewExcel::NewAST::Map)
      res.to_hash.keys.should == [:X]
    end
  end

  context "primitives - evaluating" do
    it "should be able to parse text" do
      @obj.parse("\"string\"").value.should == "string"
    end

    it "should parse an integer" do
      @obj.parse("123").value.should == 123
    end

    it "should parse a floating point" do
      @obj.parse("123.456").value.should == 123.456
    end

    it "should parse a negative number" do
      @obj.parse("-123").value.should == -123
    end

    it "should parse true as true" do
      @obj.parse("true").value.should == true
    end

    it "should parse false as false" do
      @obj.parse("false").value.should == false
    end
  end

  context "Functions" do
    it "should parse a function with an equal sign" do
      @obj.parse("= 1").should be_a_kind_of(NewExcel::NewAST::Function)
    end

    it "should parse a function with an equal sign as having zero arguments" do
      val = @obj.parse("= 1")
      val.should be_a_kind_of(NewExcel::NewAST::Function)
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

      val = @obj.parse(str)
      val.should be_a_kind_of(NewExcel::NewAST::Function)
      val.formal_arguments.should == []
    end

    it "should parse a function with an argument" do
      str = "(x) = 1"

      val = @obj.parse(str)
      val.should be_a_kind_of(NewExcel::NewAST::Function)
      val.formal_arguments.length.should == 1
      val.formal_arguments[0].should be_a_kind_of(NewExcel::NewAST::Symbol)
      val.formal_arguments[0].symbol.should == :x
    end

    it "should parse multiple function arguments" do
      str = "(x, y) = 1"

      val = @obj.parse(str)
      val.should be_a_kind_of(NewExcel::NewAST::Function)
      val.formal_arguments.length.should == 2
      val.formal_arguments[0].should be_a_kind_of(NewExcel::NewAST::Symbol)
      val.formal_arguments[0].symbol.should == :x
      val.formal_arguments[1].should be_a_kind_of(NewExcel::NewAST::Symbol)
      val.formal_arguments[1].symbol.should == :y
    end
  end
end
