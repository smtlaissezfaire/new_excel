require 'spec_helper'

describe NewExcel::Tokenizer do
  before do
    @tokenizer = NewExcel::Tokenizer
  end

  def tokenize_without_final(str)
    tokens = @tokenizer.tokenize(str)
    tokens.pop # ignore the [false, false] final token for simplicity
    tokens
  end

  it "should be able to tokenize a date like 2018-01-01" do
    tokenize_without_final("2018-01-01").should == [[:DATE_TIME, "2018-01-01"]]
  end

  it "should return the last token as [false, false]" do
    @tokenizer.tokenize("2018-01-01").should == [[:DATE_TIME, "2018-01-01"], [false, false]]
  end

  it "should have no tokens with a comment" do
    tokenize_without_final("# a comment").should == []
  end
end
