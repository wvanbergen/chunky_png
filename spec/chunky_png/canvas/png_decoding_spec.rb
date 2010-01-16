require 'spec_helper'

describe ChunkyPNG::Canvas::PNGDecoding do
  include ChunkyPNG::Canvas::PNGDecoding

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
      current  = [ 0,  0, 10, 23, 15, 13, 23, 63, 38,  60, 253,  53]
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

  describe '.from_datastream' do

    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should decode an image with color mode #{color_mode} correctly" do
        reference = ChunkyPNG::Canvas.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
        canvas = ChunkyPNG::Canvas.from_file(resource_file("gray_10x10_#{color_mode}.png"))
        canvas.should == reference
      end
    end

    it "should decode a transparent image correctly" do
      reference = ChunkyPNG::Canvas.new(10, 10, ChunkyPNG::Color.rgba(100, 100, 100, 128))
      canvas    = ChunkyPNG::Canvas.from_file(resource_file("transparent_gray_10x10.png"))
      canvas.should == reference
    end

    it "should decode an interlaced image correctly" do
      canvas_i  = ChunkyPNG::Canvas.from_file(resource_file("16x16_interlaced.png"))
      canvas_ni = ChunkyPNG::Canvas.from_file(resource_file("16x16_non_interlaced.png"))
      canvas_i.should == canvas_ni
    end
  end
end
