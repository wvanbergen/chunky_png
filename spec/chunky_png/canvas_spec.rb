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
    before(:each) do
      File.open(resource_file('pixelstream.rgba'), 'rb') { |f| @reference_data = f.read }
    end
    
    it "should load an image correctly from a datastream" do
      canvas = reference_canvas('pixelstream_reference')
      canvas.to_rgba_stream.should == @reference_data
    end
  end

  describe '#to_rgb_stream' do
    before(:each) do
      File.open(resource_file('pixelstream.rgb'), 'rb') { |f| @reference_data = f.read }
    end
    
    it "should load an image correctly from a datastream" do
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
    it "should compose pixels correctly" do
      canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
      subcanvas = ChunkyPNG::Canvas.new(4, 8, ChunkyPNG::Color.rgba(0, 0, 0, 75))
      canvas.compose(subcanvas, 8, 4)
      canvas.should == reference_canvas('composited')
    end
    
    it "should compose a base image and mask correctly" do
      base = reference_canvas('clock_base')
      mask = reference_canvas('clock_mask_updated')
      base.compose(mask).should == reference_canvas('clock_updated')
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
  
  describe '#change_theme_color!' do
    
    before(:each) do
      @theme_color = ChunkyPNG::Color.from_hex('#e10f7a')
      @new_color   = ChunkyPNG::Color.from_hex('#ff0000')
      @canvas      = reference_canvas('clock')
    end
    
    it "should change the theme color correctly" do
      @canvas.change_theme_color!(@theme_color, @new_color)
      @canvas.should == reference_canvas('clock_updated')
    end
  end
  
  describe '#extract_mask' do
    before(:each) do
      @mask_color = ChunkyPNG::Color.from_hex('#e10f7a')
      @canvas     = reference_canvas('clock')
    end
    
    it "should create the correct base and mask image" do
      base, mask = @canvas.extract_mask(@mask_color, ChunkyPNG::Color::WHITE)
      base.should == reference_canvas('clock_base')
      mask.should == reference_canvas('clock_mask')
    end
    
    it "should create a mask image with only one opaque color" do
      base, mask = @canvas.extract_mask(@mask_color, ChunkyPNG::Color::WHITE)
      mask.palette.opaque_palette.size.should == 1
    end
  end
  
  describe '#change_mask_color!' do
    before(:each) do
      @new_color = ChunkyPNG::Color.from_hex('#ff0000')
      @mask      = reference_canvas('clock_mask')
    end
    
    it "should replace the mask color correctly" do
      @mask.change_mask_color!(@new_color)
      @mask.should == reference_canvas('clock_mask_updated')
    end
    
    it "should still only have one opaque color" do
      @mask.change_mask_color!(@new_color)
      @mask.palette.opaque_palette.size.should == 1
    end
  end
end
