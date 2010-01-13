require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::Pixel do

  before(:each) do
    @white             = ChunkyPNG::Pixel.rgba(255, 255, 255, 255)
    @black             = ChunkyPNG::Pixel.rgba(  0,   0,   0, 255)
    @opaque            = ChunkyPNG::Pixel.rgba( 10, 100, 150, 255)
    @non_opaque        = ChunkyPNG::Pixel.rgba( 10, 100, 150, 100)
    @fully_transparent = ChunkyPNG::Pixel.rgba( 10, 100, 150,   0)
  end

  it "should represent pixels as the correct number" do
    @white.value.should  == 0xffffffff
    @black.value.should  == 0x000000ff
    @opaque.value.should == 0x0a6496ff
  end

  it "should correctly check for opaqueness" do
    @white.should be_opaque
    @black.should be_opaque
    @opaque.should be_opaque
    @non_opaque.should_not be_opaque
    @fully_transparent.should_not be_opaque
  end
  
  it "should convert the individual color values back correctly" do
    @opaque.to_truecolor_bytes.should == [10, 100, 150]
    @non_opaque.to_truecolor_alpha_bytes.should == [10, 100, 150, 100]
  end
  
  describe '#compose' do
    it "should use the foregorund pixel as is when an opaque pixel is given" do
      (@white & @opaque).should == @opaque
    end
    
    it "should use the background pixel as is when a fully_transparent pixel is given" do
      (@white & @fully_transparent).should == @white
    end
    
    it "should compose pixels correctly" do
      (@white.compose_quick(@non_opaque)).should   == ChunkyPNG::Pixel.new(0x9fc2d6ff)
      (@white.compose_precise(@non_opaque)).should == ChunkyPNG::Pixel.new(0x9fc2d6ff)
    end
  end
end

