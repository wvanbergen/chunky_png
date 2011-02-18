require 'spec_helper'

describe ChunkyPNG::Canvas do
  
  describe '#to_rgba_stream' do
    before { File.open(resource_file('pixelstream.rgba'), 'rb') { |f| @reference_data = f.read } }
    
    it "should load an image correctly from a datastream" do
      reference_canvas('pixelstream_reference').to_rgba_stream.should == @reference_data
    end
  end

  describe '#to_rgb_stream' do
    before { File.open(resource_file('pixelstream.rgb'), 'rb') { |f| @reference_data = f.read } }
    
    it "should load an image correctly from a datastream" do
      reference_canvas('pixelstream_reference').to_rgb_stream.should == @reference_data
    end
  end
end
