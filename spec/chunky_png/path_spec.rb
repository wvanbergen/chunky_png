require 'spec_helper'

describe ChunkyPNG::Path do
  subject { ChunkyPNG::Path.new([]) }

  it { should respond_to(:points) }
  it { should have(0).points }

  it "should create a path from a string" do
    ChunkyPNG::Path('1,1 2,2 3,3').should == ChunkyPNG::Path.new([
        ChunkyPNG::Point.new(1, 1), ChunkyPNG::Point.new(2, 2), ChunkyPNG::Point.new(3, 3)])
  end
  
  it "should create flat array" do
    ChunkyPNG::Path(1,1,2,2,3,3).should == ChunkyPNG::Path.new([
        ChunkyPNG::Point.new(1, 1), ChunkyPNG::Point.new(2, 2), ChunkyPNG::Point.new(3, 3)])
  end

  it "should create nasted array" do
    ChunkyPNG::Path([1, 1], '2x2', :x => 3, :y => 3).should == ChunkyPNG::Path.new([
        ChunkyPNG::Point.new(1, 1), ChunkyPNG::Point.new(2, 2), ChunkyPNG::Point.new(3, 3)])
  end
  
end
