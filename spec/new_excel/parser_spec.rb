require 'spec_helper'

describe NewExcel::Parser do
  before do
    @obj = NewExcel::Parser.new
  end

  context "functions" do
    it "should be able to parse a function" do
      res = @obj.parse("=add()")
      res.should be_a_kind_of(NewExcel::AST::FormulaBody)

      body = res.body

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == "add"
      body.arguments.should == []
    end

    it "should be able to parse a function with an argument" do
      res = @obj.parse("=add(1)")
      res.should be_a_kind_of(NewExcel::AST::FormulaBody)

      body = res.body

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == "add"
      body.arguments.length.should == 1
      arg = body.arguments.first

      arg.should be_a_kind_of(NewExcel::AST::PrimitiveInteger)
      arg.string.should == "1"
      arg.value.should == 1
    end

    it "should be able to parse a function with multiple arguments" do
      res = @obj.parse("=add(1, 2, 3)")
      res.should be_a_kind_of(NewExcel::AST::FormulaBody)

      body = res.body

      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.name.should == "add"
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
      res = @obj.parse("=add(1, 2)")
      res.value.should == 3
    end

    it "should parse remote cell references" do
      str = "= other_sheet.other_column"

      NewExcel::Tokenizer.get_tokens(str).should == [
        [:EQ, "="],
        [:ID, "other_sheet"],
        [:DOT, "."],
        [:ID, "other_column"],
        [false, "$end"],
      ]

      res = @obj.parse("= other_sheet.other_column")
      res.should be_a_kind_of(NewExcel::AST::FormulaBody)

      body = res.body

      body.should be_a_kind_of(NewExcel::AST::CellReference)
      body.sheet_name.should == "other_sheet"
      body.cell_name.should == "other_column"
    end

    # it "should be able to evaluate a remote cell refernece" do
    #   $context_file_path = "spec/fixtures/file.ne" # FIXME!!!
    #
    #   str = "= other_sheet.other_column"
    #
    #   NewExcel::Tokenizer.get_tokens(str).should == [
    #     [:EQ, "="],
    #     [:ID, "other_sheet"],
    #     [:DOT, "."],
    #     [:ID, "other_column"],
    #     [false, "$end"],
    #   ]
    #
    #   res = @obj.parse("= other_sheet.other_column")
    #   res.should be_a_kind_of(NewExcel::AST::CellReference)
    #   res.sheet_name.should == "other_sheet"
    #   res.cell_name.should == "other_column"
    #
    # end

    it "should allow strings passed to arguments" do
      str = "= trim(\" foo \")"

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::AST::FormulaBody)
      body = res.body
      body.should be_a_kind_of(NewExcel::AST::FunctionCall)
      body.arguments.length.should == 1

      arg = body.arguments[0]
      arg.should be_a_kind_of(NewExcel::AST::QuotedString)
      arg.value.should == " foo "
    end

    it "should be able to read a cell with a straight string" do
      str = "some"

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::AST::UnquotedString)
      res.value.should == "some"

      str = "some string text"

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::AST::UnquotedString)
      res.value.should == "some string text"
    end

    it "should be able to parse a Map" do
      str = <<-CODE
Map!
One:
  1
CODE

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::AST::Map)
      res.columns.should == [:One]

      res.value.should == [
        [:One, 1]
      ]

      res.pairs.length.should == 1
      pair = res.pairs.first
      pair.should be_a_kind_of(NewExcel::AST::KeyValuePair)

      pair.hash_key.should == :One
      pair.hash_value.should be_a_kind_of(NewExcel::AST::PrimitiveInteger)
    end

    it "should be able to parse a known file" do
      str = File.read("spec/fixtures/file.ne/simple_text.map")
      str = "Map!\n" + str

      # NewExcel::Tokenizer.get_tokens(str).should == []

      res = @obj.parse(str)
      res.should be_a_kind_of(NewExcel::AST::Map)
    end
  end

  context "primitives - evaluating" do
    # it "should be able to parse text" do
    #   @obj.parse("string").value.should == "string"
    # end

    it "should parse an integer" do
      @obj.parse("123").value.should == 123
    end

    it "should parse a floating point" do
      @obj.parse("123.456").value.should == 123.456
    end

    it "should parse a Date" do
      @obj.parse("2018-01-01").value.should == Time.parse("2018-01-01 00:00:00")
    end

    it "should parse a Time" do # FIXME?
      @obj.parse("11:00").value.should == "11:00"
    end

    it "should parse a DateTime" do
      @obj.parse("2018-01-01 11:00:00").value.should == Time.parse("2018-01-01 11:00:00")
    end

    it "should be able to parse a date with slahes" do
      @obj.parse("2019/03/01").value == Time.parse("2019-03-01 00:00:00")
    end

    it "should to parse numbers that look like numbers, but have no concrete meaning" do
      @obj.parse("114 16.75/32").value.should == "114 16.75/32"
    end
  end
end
