require "spec_helper"

describe NewExcel::RunTime::Environment do
  before do
    @environment = NewExcel::RunTime::Environment.new
  end

  it "should be expressable as a hash" do
    @environment.to_hash.should == {}
  end

  it "should be able to store things in the hash" do
    @environment[:hash] = 10
    @environment[:hash].should == 10
  end

  it "should store keys as symbols" do
    @environment["foo"] = 10
    @environment.to_hash.keys.should == [:foo]
  end

  it "should be able to look things up by symbol" do
    @environment["foo"] = 10
    @environment[:foo].should == 10
  end

  it "should be able to assign a parent environment and get keys from there" do
    parent_env = NewExcel::RunTime::Environment.new
    parent_env[:bar] = 10

    @environment.parent = parent_env
    @environment[:bar].should == 10
  end

  it "should be nil if no parent and no current key" do
    @environment.parent = nil
    @environment[:bar].should be_nil
  end

  it "should not change the parent environment if the parent also has the variable" do
    parent_env = NewExcel::RunTime::Environment.new
    parent_env[:bar] = 10

    @environment[:bar] = 20
    @environment[:bar].should == 20

    parent_env[:bar].should == 10
  end

  it "should include the variables in the parent for to_hash" do
    parent_env = NewExcel::RunTime::Environment.new
    parent_env[:bar] = 10

    @environment.parent = parent_env
    @environment[:foo] = 20
    @environment.to_hash.should == { bar: 10, foo: 20 }
  end
end
