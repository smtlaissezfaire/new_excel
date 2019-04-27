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

  it "should have no tokens with a comment" do
    tokenize_without_final("# a comment").should == []
  end
end
