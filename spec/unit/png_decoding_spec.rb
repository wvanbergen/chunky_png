require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix::PNGDecoding do
  include ChunkyPNG::PixelMatrix::PNGDecoding

  describe '#decode_png_scanline' do

    it "should decode a line without filtering as is" do
      bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      decode_png_scanline(ChunkyPNG::FILTER_NONE, bytes, nil).should == bytes
    end

    it "should decode a line with sub filtering correctly" do
      # all white pixels
      bytes = [255, 255, 255, 0, 0, 0, 0, 0, 0]
      decoded_bytes = decode_png_scanline(ChunkyPNG::FILTER_SUB, bytes, nil)
      decoded_bytes.should == [255, 255, 255, 255, 255, 255, 255, 255, 255]

      # all black pixels
      bytes = [0, 0, 0, 0, 0, 0, 0, 0, 0]
      decoded_bytes = decode_png_scanline(ChunkyPNG::FILTER_SUB, bytes, nil)
      decoded_bytes.should == [0, 0, 0, 0, 0, 0, 0, 0, 0]

      # various colors
      bytes = [255, 0, 45, 0, 255, 0, 112, 200, 178]
      decoded_bytes = decode_png_scanline(ChunkyPNG::FILTER_SUB, bytes, nil)
      decoded_bytes.should == [255, 0, 45, 255, 255, 45, 111, 199, 223]
    end

    it "should decode a line with up filtering correctly" do
      # previous line is all black
      previous_bytes = [0, 0, 0, 0, 0, 0, 0, 0, 0]
      bytes          = [255, 255, 255, 127, 127, 127, 0, 0, 0]
      decoded_bytes  = decode_png_scanline(ChunkyPNG::FILTER_UP, bytes, previous_bytes)
      decoded_bytes.should == [255, 255, 255, 127, 127, 127, 0, 0, 0]

      # previous line has various pixels
      previous_bytes = [255, 255, 255, 127, 127, 127, 0, 0, 0]
      bytes          = [0, 127, 255, 0, 127, 255, 0, 127, 255]
      decoded_bytes  = decode_png_scanline(ChunkyPNG::FILTER_UP, bytes, previous_bytes)
      decoded_bytes.should == [255, 126, 254, 127, 254, 126, 0, 127, 255]
    end
    
    it "should decode a line with average filtering correctly" do
      previous = [10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120]
      current  = [ 0,  0, 10, 20, 10,  0,  0, 40, 10,  20, 190,   0]
      decoded  = decode_png_scanline(ChunkyPNG::FILTER_AVERAGE, current, previous)
      decoded.should == [5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165]
    end

    it "should decode a line with paeth filtering correctly" do
      previous = [10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120]
      current  = [ 0,  0, 10, 20, 10,  0,  0, 40, 10,  20, 190,   0]
      decoded  = decode_png_scanline(ChunkyPNG::FILTER_PAETH, current, previous)
      decoded.should == [10, 20, 40, 60, 60, 60, 70, 120, 90, 120, 54, 120]
    end
  end

  describe '#adam7_pass_sizes' do
    it "should get the pass sizes for a 8x8 image correctly" do
      adam7_pass_sizes(8, 8).should == [
          [1, 1], [1, 1], [2, 1], [2, 2], [4, 2], [4, 4], [8, 4]
        ]
    end

    it "should get the pass sizes for a 12x12 image correctly" do
      adam7_pass_sizes(12, 12).should == [
          [2, 2], [1, 2], [3, 1], [3, 3], [6, 3], [6, 6], [12, 6]
        ]
    end

    it "should get the pass sizes for a 33x47 image correctly" do
      adam7_pass_sizes(33, 47).should == [
          [5, 6], [4, 6], [9, 6], [8, 12], [17, 12], [16, 24], [33, 23]
        ]
    end

    it "should get the pass sizes for a 1x1 image correctly" do
      adam7_pass_sizes(1, 1).should == [
          [1, 1], [0, 1], [1, 0], [0, 1], [1, 0], [0, 1], [1, 0]
        ]
    end

    it "should get the pass sizes for a 0x0 image correctly" do
      adam7_pass_sizes(0, 0).should == [
          [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]
        ]
    end

    it "should always maintain the same amount of pixels in total" do
      [[8, 8], [12, 12], [33, 47], [1, 1], [0, 0]].each do |(width, height)|
        pass_sizes = adam7_pass_sizes(width, height)
        pass_sizes.inject(0) { |sum, (w, h)| sum + (w*h) }.should == width * height
      end
    end
  end
  
  describe '.from_datastream' do

    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should decode an image with color mode #{color_mode} correctly" do
        reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
        matrix = ChunkyPNG::PixelMatrix.from_file(resource_file("gray_10x10_#{color_mode}.png"))
        matrix.should == reference
      end
    end

    it "should decode a transparent image correctly" do
      reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Color.rgba(100, 100, 100, 128))
      matrix    = ChunkyPNG::PixelMatrix.from_file(resource_file("transparent_gray_10x10.png"))
      matrix.should == reference
    end

    it "should decode an interlaced image correctly" do
      matrix_i  = ChunkyPNG::PixelMatrix.from_file(resource_file("16x16_interlaced.png"))
      matrix_ni = ChunkyPNG::PixelMatrix.from_file(resource_file("16x16_non_interlaced.png"))
      matrix_i.should == matrix_ni
    end
  end
end
