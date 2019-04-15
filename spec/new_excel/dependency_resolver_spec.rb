require "spec_helper"

describe NewExcel::DependencyResolver do
  before do
    @resolver = NewExcel::DependencyResolver.new
  end

  it "should have an empty list to start" do
    @resolver.dependencies.should == {}
  end

  it "should be able to add a dependency" do
    @resolver.add_dependency("a", "b")
    @resolver.dependencies["a"].should == ["b"]
  end

  def create_example_graph
    @resolver.add_dependency("a", "b")
    @resolver.add_dependency("a", "d")
    @resolver.add_dependency("b", "c")
    @resolver.add_dependency("b", "e")
    @resolver.add_dependency("c", "d")
    @resolver.add_dependency("c", "e")
    @resolver.add_dependency("x", "e")
  end

  it "should be able to add multiple dependencies" do
    create_example_graph

    @resolver.dependencies.keys.should == ["a", "b", "c", "x"]

    @resolver.dependencies["a"].should == ["b", "d"]
    @resolver.dependencies["b"].should == ["c", "e"]
    @resolver.dependencies["c"].should == ["d", "e"]
  end

  describe "resolving dependencies" do
    before do
      create_example_graph
    end

    it "should return an empty list if there are no dependencies" do
      @resolver.resolve("e").should == []
    end

    it "should resolve a straight forward dependency" do
      @resolver.resolve("x").should == ["e"]
    end

    it "should resolve indirect dependencies" do
      @resolver.resolve("a").should == ["d", "e", "c", "b"]
    end

    it "should resolve circular dependencies" do
      @resolver.add_dependency("d", "b")

      lambda {
        @resolver.resolve("a")
      }.should raise_error(NewExcel::DependencyResolver::CircularDependencyError, "Circular reference detected: d -> b")
    end

    it "should invalidate resolutions when a new node is added" do
      @resolver.resolve("a").should == ["d", "e", "c", "b"]
      @resolver.add_dependency("e", "f")
      @resolver.resolve("a").should == ["d", "f", "e", "c", "b"]
    end
  end
end
