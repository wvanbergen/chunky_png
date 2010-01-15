require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::Color do
  include ChunkyPNG::Color

  before(:each) do
    @white             = rgba(255, 255, 255, 255)
    @black             = rgba(  0,   0,   0, 255)
    @opaque            = rgba( 10, 100, 150, 255)
    @non_opaque        = rgba( 10, 100, 150, 100)
    @fully_transparent = rgba( 10, 100, 150,   0)
  end

  it "should represent pixels as the correct number" do
    @white.should  == 0xffffffff
    @black.should  == 0x000000ff
    @opaque.should == 0x0a6496ff
  end

  it "should correctly check for opaqueness" do
    opaque?(@white).should be_true
    opaque?(@black).should be_true
    opaque?(@opaque).should be_true
    opaque?(@non_opaque).should be_false
    opaque?(@fully_transparent).should be_false
  end

  it "should convert the individual color values back correctly" do
    truecolor_bytes(@opaque).should == [10, 100, 150]
    truecolor_alpha_bytes(@non_opaque).should == [10, 100, 150, 100]
  end

  describe '#compose' do
    it "should use the foregorund color as is when an opaque color is given as foreground color" do
      compose(@opaque, @white).should == @opaque
    end

    it "should use the background color as is when a fully transparent pixel is given as foreground color" do
      compose(@fully_transparent, @white).should == @white
    end

    it "should compose pixels correctly" do
      compose_quick(@non_opaque, @white).should   == 0x9fc2d6ff
      compose_precise(@non_opaque, @white).should == 0x9fc2d6ff
    end
  end
  
  describe '#blend' do
    it "should blend colors correctly" do
      blend(@opaque, @black).should == 0x05324bff
    end
    
    it "should not matter what color is used as foreground, and what as background" do
      blend(@opaque, @black).should == blend(@black, @opaque)
    end
  end
end

