require 'spec_helper'

describe ChunkyPNG::Canvas::PNGDecoding do
  include ChunkyPNG::Canvas::PNGDecoding

  describe '#decode_png_scanline' do

    it "should decode a line without filtering as is" do
      stream = [ChunkyPNG::FILTER_NONE, 255, 255, 255, 255, 255, 255, 255, 255, 255].pack('C*')
      decode_png_str_scanline(stream, 0, nil, 9, 3)
      stream.unpack('@1C*').should == [255, 255, 255, 255, 255, 255, 255, 255, 255]
    end

    it "should decode a line with sub filtering correctly" do
      # all white pixels
      stream = [ChunkyPNG::FILTER_SUB, 255, 255, 255, 0, 0, 0, 0, 0, 0].pack('C*')
      decode_png_str_scanline(stream, 0, nil, 9, 3)
      stream.unpack('@1C*').should == [255, 255, 255, 255, 255, 255, 255, 255, 255]

      # all black pixels
      stream = [ChunkyPNG::FILTER_SUB, 0, 0, 0, 0, 0, 0, 0, 0, 0].pack('C*')
      decode_png_str_scanline(stream, 0, nil, 9, 3)
      stream.unpack('@1C*').should == [0, 0, 0, 0, 0, 0, 0, 0, 0]

      # various colors
      stream = [ChunkyPNG::FILTER_SUB, 255, 0, 45, 0, 255, 0, 112, 200, 178].pack('C*')
      decode_png_str_scanline(stream, 0, nil, 9, 3)
      stream.unpack('@1C*').should == [255, 0, 45, 255, 255, 45, 111, 199, 223]
    end

    it "should decode a line with up filtering correctly" do
      # previous line has various pixels
      previous = [ChunkyPNG::FILTER_UP, 255, 255, 255, 127, 127, 127, 0, 0, 0]
      current  = [ChunkyPNG::FILTER_UP, 0, 127, 255, 0, 127, 255, 0, 127, 255]
      stream   = (previous + current).pack('C*')
      decode_png_str_scanline(stream, 10, 0, 9, 3)
      stream.unpack('@11C9').should == [255, 126, 254, 127, 254, 126, 0, 127, 255]
    end
    
    it "should decode a line with average filtering correctly" do
      previous = [ChunkyPNG::FILTER_AVERAGE, 10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120]
      current  = [ChunkyPNG::FILTER_AVERAGE,  0,  0, 10, 23, 15, 13, 23, 63, 38,  60, 253,  53]
      stream   = (previous + current).pack('C*')
      decode_png_str_scanline(stream, 13, 0, 12, 3)
      stream.unpack('@14C12').should == [5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165]
    end

    it "should decode a line with paeth filtering correctly" do
      previous = [ChunkyPNG::FILTER_PAETH, 10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120]
      current  = [ChunkyPNG::FILTER_PAETH,  0,  0, 10, 20, 10,  0,  0, 40, 10,  20, 190,   0]
      stream   = (previous + current).pack('C*')
      decode_png_str_scanline(stream, 13, 0, 12, 3)
      stream.unpack('@14C12').should == [10, 20, 40, 60, 60, 60, 70, 120, 90, 120, 54, 120]
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

    it "should raise an error if the color depth is not supported" do
      filename = resource_file('indexed_4bit.png')
      lambda { ChunkyPNG::Canvas.from_file(filename) }.should raise_error
    end
  end
end
