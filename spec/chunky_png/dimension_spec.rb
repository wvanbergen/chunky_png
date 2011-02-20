require 'spec_helper'

describe ChunkyPNG::Dimension do
  subject { ChunkyPNG::Dimension.new(2, 3) }
  
  it { should respond_to(:width) }
  it { should respond_to(:height) }
  
  describe '#area' do
    it "should calculate the area correctly" do
      subject.area.should == 6
    end
  end
end
