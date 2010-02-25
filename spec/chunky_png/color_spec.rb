require 'spec_helper'

describe ChunkyPNG::Color do
  include ChunkyPNG::Color

  before(:each) do
    @white             = 0xffffffff
    @black             = 0x000000ff
    @opaque            = 0x0a6496ff
    @non_opaque        = 0x0a649664
    @fully_transparent = 0x0a649600
  end

  describe '#rgba' do
    it "should represent pixels as the correct number" do
      rgba(255, 255, 255, 255).should == @white
      rgba(  0,   0,   0, 255).should == @black
      rgba( 10, 100, 150, 255).should == @opaque
      rgba( 10, 100, 150, 100).should == @non_opaque
      rgba( 10, 100, 150,   0).should == @fully_transparent
    end
  end
  
  describe '#from_hex' do
    it "should load colors correctlt from hex notation" do
      from_hex('0a649664').should   == @non_opaque
      from_hex('#0a649664').should  == @non_opaque
      from_hex('0x0a649664').should == @non_opaque
      from_hex('0a6496').should     == @opaque
      from_hex('#0a6496').should    == @opaque
      from_hex('0x0a6496').should   == @opaque
    end
  end
  
  describe '#opaque?' do
    it "should correctly check for opaqueness" do
      opaque?(@white).should be_true
      opaque?(@black).should be_true
      opaque?(@opaque).should be_true
      opaque?(@non_opaque).should be_false
      opaque?(@fully_transparent).should be_false
    end
  end
  
  describe 'extractiion of separate color channels' do
    it "should extract components from a color correctly" do
      r(@opaque).should == 10
      g(@opaque).should == 100
      b(@opaque).should == 150
      a(@opaque).should == 255
    end
  end
  
  describe '#to_hex' do
    it "should represent colors correcly using hex notation" do
      to_hex(@white).should == '#ffffffff'
      to_hex(@black).should == '#000000ff'
      to_hex(@opaque).should == '#0a6496ff'
      to_hex(@non_opaque).should == '#0a649664'
      to_hex(@fully_transparent).should == '#0a649600'
    end
    
    it "should represent colors correcly using hex notation without alpha channel" do
      to_hex(@white, false).should == '#ffffff'
      to_hex(@black, false).should == '#000000'
      to_hex(@opaque, false).should == '#0a6496'
      to_hex(@non_opaque, false).should == '#0a6496'
      to_hex(@fully_transparent, false).should == '#0a6496'
    end
  end

  describe 'conversion to other formats' do
    it "should convert the individual color values back correctly" do
      to_truecolor_bytes(@opaque).should == [10, 100, 150]
      to_truecolor_alpha_bytes(@non_opaque).should == [10, 100, 150, 100]
    end
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
  
  describe '#decompose_alpha' do
    it "should decompose the alpha channel correctly" do
      decompose_alpha(0x9fc2d6ff, @opaque, @white).should == 0x00000064
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

