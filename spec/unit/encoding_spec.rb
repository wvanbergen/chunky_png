require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix::Encoding do
  include ChunkyPNG::PixelMatrix::Encoding
  
  describe '#encode_scanline' do
    
    it "should encode a scanline without filtering correctly" do
      bytes = [0, 0, 0, 1, 1, 1, 2, 2, 2]
      encoded_bytes = encode_scanline(ChunkyPNG::FILTER_NONE, bytes, nil)
      encoded_bytes.should == [0, 0, 0, 0, 1, 1, 1, 2, 2, 2]
    end
    
    it "should encode a scanline with sub filtering correctly" do
      bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded_bytes = encode_scanline(ChunkyPNG::FILTER_SUB, bytes, nil)
      encoded_bytes.should == [1, 255, 255, 255, 0, 0, 0, 0, 0, 0]
    end
    
    it "should encode a scanline with up filtering correctly" do
      bytes          = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      previous_bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255]
      encoded_bytes  = encode_scanline(ChunkyPNG::FILTER_UP, bytes, previous_bytes)
      encoded_bytes.should == [2, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
