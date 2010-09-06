require 'spec_helper'

describe ChunkyPNG::Canvas::Operations do
  describe '#crop' do
    before { @canvas = reference_canvas('operations') }

    it "should crop the right pixels from the original canvas" do
      cropped = @canvas.crop(10, 5, 4, 8)
      cropped.should == reference_canvas('cropped')
    end
    
    it "should raise an exception when the cropped image falls outside the oiginal image" do
      lambda { @canvas.crop(16, 16, 2, 2) }.should raise_error(ChunkyPNG::OutOfBounds)
    end
  end

  describe '#compose' do
    it "should compose pixels correctly" do
      canvas = reference_canvas('operations')
      subcanvas = ChunkyPNG::Canvas.new(4, 8, ChunkyPNG::Color.rgba(0, 0, 0, 75))
      canvas.compose(subcanvas, 8, 4)
      canvas.should == reference_canvas('composited')
    end
    
    it "should compose a base image and mask correctly" do
      base = reference_canvas('clock_base')
      mask = reference_canvas('clock_mask_updated')
      base.compose(mask).should == reference_canvas('clock_updated')
    end
    
    it "should raise an exception when the pixels to compose fall outside the image" do
      lambda { reference_canvas('operations').compose(ChunkyPNG::Canvas.new(1,1), 16, 16) }.should raise_error(ChunkyPNG::OutOfBounds)
    end
  end

  describe '#replace' do
    before { @canvas = reference_canvas('operations') }

    it "should replace the correct pixels" do
      subcanvas = ChunkyPNG::Canvas.new(3, 2, ChunkyPNG::Color.rgb(200, 255, 0))
      @canvas.replace(subcanvas, 5, 4)
      @canvas.should == reference_canvas('replaced')
    end
    
    it "should raise an exception when the pixels to replace fall outside the image" do
      lambda { @canvas.replace(ChunkyPNG::Canvas.new(1,1), 16, 16) }.should raise_error(ChunkyPNG::OutOfBounds)
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
    
    it "should raise an exception when the mask image has more than once color" do
      not_a_mask = reference_canvas('operations')
      lambda { not_a_mask.change_mask_color!(@new_color) }.should raise_error(ChunkyPNG::ExpectationFailed)
    end
  end
end

describe ChunkyPNG::Canvas::Operations do
  before { @stubbed = reference_canvas('clock_stubbed') }

  describe '#flip_horizontally' do
    it "should flip the pixels horizontally" do
      @stubbed.flip_horizontally.should == reference_canvas('clock_flip_horizontally')
    end
    
    it "should return itself when applied twice" do
      @stubbed.flip_horizontally.flip_horizontally.should == @stubbed
    end
  end

  describe '#flip_vertically' do
    it "should flip the pixels vertically" do
      @stubbed.flip_vertically.should == reference_canvas('clock_flip_vertically')
    end
    
    it "should return itself when applied twice" do
      @stubbed.flip_vertically.flip_vertically.should == @stubbed
    end
  end

  describe '#rotate_left' do
    it "should rotate the pixels 90 degrees counter-clockwise" do
      @stubbed.rotate_left.should == reference_canvas('clock_rotate_left')
    end
    
    it "it should rotate 180 degrees when applied twice" do
      @stubbed.rotate_left.rotate_left.should == reference_canvas('clock_rotate_180')
    end
    
    it "it should rotate right when applied three times" do
      @stubbed.rotate_left.rotate_left.rotate_left.should == reference_canvas('clock_rotate_right')
    end
    
    it "should return itself when applied four times" do
      @stubbed.rotate_left.rotate_left.rotate_left.rotate_left.should == @stubbed
    end
  end

  describe '#rotate_right' do
    it "should rotate the pixels 90 degrees clockwise" do
      @stubbed.rotate_right.should == reference_canvas('clock_rotate_right')
    end
    
    it "it should rotate 180 degrees when applied twice" do
      @stubbed.rotate_right.rotate_right.should == reference_canvas('clock_rotate_180')
    end
    
    it "it should rotate left when applied three times" do
      @stubbed.rotate_right.rotate_right.rotate_right.should == reference_canvas('clock_rotate_left')
    end
    
    it "should return itself when applied four times" do
      @stubbed.rotate_right.rotate_right.rotate_right.rotate_right.should == @stubbed
    end
  end

  describe '#rotate_180' do
    it "should rotate the pixels 180 degrees" do
      @stubbed.rotate_180.should == reference_canvas('clock_rotate_180')
    end
    
    it "should return itself when applied twice" do
      @stubbed.rotate_180.rotate_180.should == @stubbed
    end
  end
end
