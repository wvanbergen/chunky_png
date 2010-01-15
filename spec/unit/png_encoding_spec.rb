require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix::PNGEncoding do
  include ChunkyPNG::PixelMatrix::PNGEncoding

  describe '.encode' do
    before(:each) do
      @matrix = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
    end

    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should encode an image with color mode #{color_mode} correctly" do
        filename = resource_file("_tmp_#{color_mode}.png")        
        @matrix.save(filename, :color_mode => ChunkyPNG.const_get("COLOR_#{color_mode.to_s.upcase}"))
        ChunkyPNG::PixelMatrix.from_file(filename).should == @matrix
        File.unlink(filename)
      end
    end
  end

  describe '#encode_scanline' do

    it "should encode a scanline without filtering correctly" do
      current = [0, 0, 0, 1, 1, 1, 2, 2, 2]
      encoded = encode_png_scanline(ChunkyPNG::FILTER_NONE, current, nil)
      encoded.should == [0, 0, 0, 0, 1, 1, 1, 2, 2, 2]
    end

    it "should encode a scanline with sub filtering correctly" do
      current = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded = encode_png_scanline(ChunkyPNG::FILTER_SUB, current, nil)
      encoded.should == [1, 255, 255, 255, 0, 0, 0, 0, 0, 0]
    end

    it "should encode a scanline with up filtering correctly" do
      previous = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      current  = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded  = encode_png_scanline(ChunkyPNG::FILTER_UP, current, previous)
      encoded.should == [2, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
    
    it "should encode a scanline with average filtering correctly" do
      previous = [10, 20, 30, 40, 50, 60, 70, 80,   80, 100, 110, 120]
      current  = [ 5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165]
      encoded  = encode_png_scanline(ChunkyPNG::FILTER_AVERAGE, current, previous)
      encoded.should == [3, 0,  0, 10, 20, 10,  0,  0, 40, 10,  20, 190,   0]
    end
    
    it "should encode a scanline with paeth filtering correctly" do
      previous = [10, 20, 30, 40, 50, 60, 70, 80,  80, 100, 110, 120]
      current  = [10, 20, 40, 60, 60, 60, 70, 120, 90, 120,  54, 120]
      encoded  = encode_png_scanline(ChunkyPNG::FILTER_PAETH, current, previous)
      encoded.should == [4, 0,  0, 10, 20, 10,  0,  0, 40, 10,  20, 190,   0]
    end
  end
end
