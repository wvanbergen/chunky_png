require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix do
  
  describe '.decode' do
    
    before(:each) do
      @reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Pixel.rgb(100, 100, 100))
    end
    
    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should decode an image with color mode #{color_mode} correctly" do
        ds = ChunkyPNG.load(resource_file("gray_10x10_#{color_mode}.png"))
        ds.pixel_matrix.should == @reference
      end
    end
  end
  
  describe '.encode' do
    before(:each) do
      @reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Pixel.rgb(100, 100, 100))
    end
    
    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should encode an image with color mode #{color_mode} correctly" do

        filename = resource_file("_tmp_#{color_mode}.png")
        File.open(filename, 'w') { |f| @reference.to_datastream.write(f) }
        
        ChunkyPNG.load(filename).pixel_matrix.should == @reference
        
        File.unlink(filename)
      end
    end
    
  end
end
