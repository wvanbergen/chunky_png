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
      bytes = [0, 0, 0, 1, 1, 1, 2, 2, 2]
      encoded_bytes = encode_png_scanline(ChunkyPNG::FILTER_NONE, bytes, nil)
      encoded_bytes.should == [0, 0, 0, 0, 1, 1, 1, 2, 2, 2]
    end

    it "should encode a scanline with sub filtering correctly" do
      bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded_bytes = encode_png_scanline(ChunkyPNG::FILTER_SUB, bytes, nil)
      encoded_bytes.should == [1, 255, 255, 255, 0, 0, 0, 0, 0, 0]
    end

    it "should encode a scanline with up filtering correctly" do
      bytes          = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      previous_bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded_bytes  = encode_png_scanline(ChunkyPNG::FILTER_UP, bytes, previous_bytes)
      encoded_bytes.should == [2, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
