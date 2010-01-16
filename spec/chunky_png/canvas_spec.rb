require 'spec_helper'

describe ChunkyPNG::Canvas do

  describe '.from_rgb_stream' do
    it "should load an image correctly from a datastrean" do
      File.open(resource_file('pixelstream.rgb')) do |stream|
        matrix = ChunkyPNG::Canvas.from_rgb_stream(240, 180, stream)
        matrix.should == reference_canvas('pixelstream_reference')
      end
    end
  end

  describe '.from_rgba_stream' do
    it "should load an image correctly from a datastrean" do
      File.open(resource_file('pixelstream.rgba')) do |stream|
        matrix = ChunkyPNG::Canvas.from_rgba_stream(240, 180, stream)
        matrix.should == reference_canvas('pixelstream_reference')
      end
    end
  end
  
  describe '#to_rgba_stream' do
    before (:each) do
      File.open(resource_file('pixelstream.rgba'), 'rb') { |f| @reference_data = f.read }
    end
    
    it "should load an image correctly from a datastrean" do
      canvas = reference_canvas('pixelstream_reference')
      canvas.to_rgba_stream.should == @reference_data
    end
  end

  describe '#to_rgb_stream' do
    before (:each) do
      File.open(resource_file('pixelstream.rgb'), 'rb') { |f| @reference_data = f.read }
    end
    
    it "should load an image correctly from a datastrean" do
      canvas = reference_canvas('pixelstream_reference')
      canvas.to_rgb_stream.should == @reference_data
    end
  end

  describe '#crop' do
    before(:each) do
      @canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
    end

    it "should crop the right pixels from the original canvas" do
      cropped = @canvas.crop(10, 5, 4, 8)
      cropped.should == reference_canvas('cropped')
    end
  end

  describe '#compose' do
    before(:each) do
      @canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
    end

    it "should compose pixels correctly" do
      subcanvas = ChunkyPNG::Canvas.new(4, 8, ChunkyPNG::Color.rgba(0, 0, 0, 75))
      @canvas.compose(subcanvas, 8, 4)
      @canvas.should == reference_canvas('composited')
    end
  end

  describe '#replace' do
    before(:each) do
      @canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
    end

    it "should replace the correct pixels" do
      subcanvas = ChunkyPNG::Canvas.new(3, 2, ChunkyPNG::Color.rgb(200, 255, 0))
      @canvas.replace(subcanvas, 5, 4)
      @canvas.should == reference_canvas('replaced')
    end
  end
end
