require 'spec_helper'

describe ChunkyPNG::Point do
  
  subject { ChunkyPNG::Point.new(1, 2) }
  
  it { should respond_to(:x) }
  it { should respond_to(:y) }
  
  describe '.single' do
    
    it "should create a point from a 2-item array" do
      ChunkyPNG::Point[[1, 2]].should     == ChunkyPNG::Point.new(1, 2)
      ChunkyPNG::Point[['1', '2']].should == ChunkyPNG::Point.new(1, 2)
    end
    
    it "should create a point from a hash with x and y keys" do
      ChunkyPNG::Point[:x => 1, :y => 2].should       == ChunkyPNG::Point.new(1, 2)
      ChunkyPNG::Point['x' => '1', 'y' => '2'].should == ChunkyPNG::Point.new(1, 2)
    end
    
    it "should create a point from a point-like string" do
      ChunkyPNG::Point['1,2'].should     == subject
      ChunkyPNG::Point['1   2'].should   == subject
      ChunkyPNG::Point['(1 , 2)'].should == ChunkyPNG::Point.new(1, 2)
      ChunkyPNG::Point["{1,\t2}"].should == ChunkyPNG::Point.new(1, 2)
      ChunkyPNG::Point["[1,2}"].should   == ChunkyPNG::Point.new(1, 2)
    end
    
    it "should raise an exception if the input is not understood" do
      lambda { ChunkyPNG::Point[Object.new] }.should raise_error(ChunkyPNG::ExpectationFailed)
    end
  end
  
  describe '.multiple' do
    
    it "should return an empty array when given an empty array" do
      ChunkyPNG::Point.multiple([]).should == []
    end
    
    it "should return a list of points given an array of numerics" do
      ChunkyPNG::Point.multiple([1, 2, 3, 4]).should == [ChunkyPNG::Point.new(1, 2), ChunkyPNG::Point.new(3, 4)]
    end
    
    it "should raise an error when an odd number of numerics is given" do
      lambda { ChunkyPNG::Point.multiple([1, 2, 3]) }.should raise_error(ChunkyPNG::ExpectationFailed)
    end
    
    it "should return a list of points given an array of point-like objects" do
      ChunkyPNG::Point.multiple([[1,2], '3,4']).should == [ChunkyPNG::Point.new(1, 2), ChunkyPNG::Point.new(3, 4)]
    end
    
    it "should return a list of points given a string of numerics" do
      ChunkyPNG::Point.multiple('1 2 3 4').should         == [ChunkyPNG::Point.new(1, 2), ChunkyPNG::Point.new(3, 4)]
      ChunkyPNG::Point.multiple('1, 2, 3, 4').should      == [ChunkyPNG::Point.new(1, 2), ChunkyPNG::Point.new(3, 4)]
      ChunkyPNG::Point.multiple('1,2 3,4').should         == [ChunkyPNG::Point.new(1, 2), ChunkyPNG::Point.new(3, 4)]
      ChunkyPNG::Point.multiple('(1 , 2) [3 , 4}').should == [ChunkyPNG::Point.new(1, 2), ChunkyPNG::Point.new(3, 4)]
    end
  end
  
  describe '#within_bounds?' do
    it { should     be_within_bounds(2, 3) }
    it { should_not be_within_bounds(1, 3) }
    it { should_not be_within_bounds(2, 2) }
    it { should_not be_within_bounds(1, 2) }
  end
  
  describe '#<=>' do
    it "should return 0 if the coordinates are identical" do
      (subject <=> ChunkyPNG::Point.new(1, 2)).should == 0
    end

    it "should return -1 if the y coordinate is smaller than the other one" do
      (subject <=> ChunkyPNG::Point.new(1, 3)).should == -1
      (subject <=> ChunkyPNG::Point.new(0, 3)).should == -1 # x doesn't matter
      (subject <=> ChunkyPNG::Point.new(2, 3)).should == -1 # x doesn't matter
    end

    it "should return 1 if the y coordinate is larger than the other one" do
      (subject <=> ChunkyPNG::Point.new(1, 0)).should == 1
      (subject <=> ChunkyPNG::Point.new(0, 0)).should == 1 # x doesn't matter
      (subject <=> ChunkyPNG::Point.new(2, 0)).should == 1 # x doesn't matter
    end

    it "should return -1 if the x coordinate is smaller and y is the same" do
      (subject <=> ChunkyPNG::Point.new(2, 2)).should == -1
    end

    it "should return 1 if the x coordinate is larger and y is the same" do
      (subject <=> ChunkyPNG::Point.new(0, 2)).should == 1
    end
  end
end
