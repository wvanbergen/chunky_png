require 'spec_helper'

describe ChunkyPNG::Canvas do

  describe '.from_rgb_stream' do
    it "should load an image correctly from a datastream" do
      File.open(resource_file('pixelstream.rgb')) do |stream|
        matrix = ChunkyPNG::Canvas.from_rgb_stream(240, 180, stream)
        matrix.should == reference_canvas('pixelstream_reference')
      end
    end
  end

  describe '.from_rgba_stream' do
    it "should load an image correctly from a datastream" do
      File.open(resource_file('pixelstream.rgba')) do |stream|
        matrix = ChunkyPNG::Canvas.from_rgba_stream(240, 180, stream)
        matrix.should == reference_canvas('pixelstream_reference')
      end
    end
  end
  
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
  
  describe '#row' do
    before { @canvas = reference_canvas('operations') }

    it "should give an out of bounds exception when y-coordinate is out of bounds" do
      lambda { @canvas.row(-1) }.should raise_error(ChunkyPNG::OutOfBounds)
      lambda { @canvas.row(16) }.should raise_error(ChunkyPNG::OutOfBounds)
    end

    it "should return the correct pixels" do
      data = @canvas.row(0)
      data.should have(@canvas.width).items
      data.should == [65535, 268500991, 536936447, 805371903, 1073807359, 1342242815, 1610678271, 1879113727, 2147549183, 2415984639, 2684420095, 2952855551, 3221291007, 3489726463, 3758161919, 4026597375]
    end
  end

  describe '#column' do
    before { @canvas = reference_canvas('operations') }

    it "should give an out of bounds exception when x-coordinate is out of bounds" do
      lambda { @canvas.column(-1) }.should raise_error(ChunkyPNG::OutOfBounds)
      lambda { @canvas.column(16) }.should raise_error(ChunkyPNG::OutOfBounds)
    end

    it "should return the correct pixels" do
      data = @canvas.column(0)
      data.should have(@canvas.height).items
      data.should == [65535, 1114111, 2162687, 3211263, 4259839, 5308415, 6356991, 7405567, 8454143, 9502719, 10551295, 11599871, 12648447, 13697023, 14745599, 15794175]
    end
  end
end
