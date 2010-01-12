require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix do
  
  describe '#decode_scanline' do
    before(:each) do
      @matrix = ChunkyPNG::PixelMatrix.new(3, 3)
    end
    
    it "should decode a line without filtering as is" do
      bytes = Array.new(@matrix.width * 3, ChunkyPNG::Pixel.rgb(10, 20, 30))
      @matrix.decode_scanline(ChunkyPNG::PixelMatrix::FILTER_NONE, bytes, nil).should == bytes
    end
    
    it "should decode a line with sub filtering correctly" do
      # all white pixels
      bytes = [255, 255, 255, 0, 0, 0, 0, 0, 0]
      decoded_bytes = @matrix.decode_scanline(ChunkyPNG::PixelMatrix::FILTER_SUB, bytes, nil)
      decoded_bytes.should == [255, 255, 255, 255, 255, 255, 255, 255, 255]
      
      # all black pixels
      bytes = [0, 0, 0, 0, 0, 0, 0, 0, 0]
      decoded_bytes = @matrix.decode_scanline(ChunkyPNG::PixelMatrix::FILTER_SUB, bytes, nil)
      decoded_bytes.should == [0, 0, 0, 0, 0, 0, 0, 0, 0]
      
      # various colors
      bytes = [255, 0, 45, 0, 255, 0, 112, 200, 178]
      decoded_bytes = @matrix.decode_scanline(ChunkyPNG::PixelMatrix::FILTER_SUB, bytes, nil)
      decoded_bytes.should == [255, 0, 45, 255, 255, 45, 111, 199, 223]
    end
    
    it "should decode a line with up filtering correctly" do
      # previous line is all black
      previous_bytes = [0, 0, 0, 0, 0, 0, 0, 0, 0]
      bytes          = [255, 255, 255, 127, 127, 127, 0, 0, 0]
      decoded_bytes = @matrix.decode_scanline(ChunkyPNG::PixelMatrix::FILTER_UP, bytes, previous_bytes)
      decoded_bytes.should == [255, 255, 255, 127, 127, 127, 0, 0, 0]
      
      # previous line has various pixels
      previous_bytes = [255, 255, 255, 127, 127, 127, 0, 0, 0]
      bytes          = [0, 127, 255, 0, 127, 255, 0, 127, 255]
      decoded_bytes = @matrix.decode_scanline(ChunkyPNG::PixelMatrix::FILTER_UP, bytes, previous_bytes)
      decoded_bytes.should == [255, 126, 254, 127, 254, 126, 0, 127, 255]
    end
  end
  
  describe '#encode_scanline' do
    before(:each) do
      @matrix = ChunkyPNG::PixelMatrix.new(3, 3)
    end
    
    it "should encode a scanline without filtering correctly" do
      bytes = [0, 0, 0, 1, 1, 1, 2, 2, 2]
      encoded_bytes = @matrix.encode_scanline(ChunkyPNG::PixelMatrix::FILTER_NONE, bytes, nil, nil)
      encoded_bytes.should == [0, 0, 0, 0, 1, 1, 1, 2, 2, 2]
    end
    
    it "should encode a scanline with sub filtering correctly" do
      bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded_bytes = @matrix.encode_scanline(ChunkyPNG::PixelMatrix::FILTER_SUB, bytes, nil, nil)
      encoded_bytes.should == [1, 255, 255, 255, 0, 0, 0, 0, 0, 0]
    end
    
    it "should encode a scanline with up filtering correctly" do
      bytes          = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      previous_bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded_bytes = @matrix.encode_scanline(ChunkyPNG::PixelMatrix::FILTER_UP, bytes, previous_bytes, nil)
      encoded_bytes.should == [2, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end    
  end
end
