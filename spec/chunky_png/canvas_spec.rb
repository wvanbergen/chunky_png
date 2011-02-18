require 'spec_helper'

describe ChunkyPNG::Canvas do

  describe '.from_rgb_stream' do
    it "should load an image correctly from a datastream" do
      File.open(resource_file('pixelstream.rgb')) do |stream|
        matrix = ChunkyPNG::Canvas.from_rgb_stream(240, 180, stream)
        matrix.should == reference_canvas('pixelstream_reference')
      end
    end
  end

  describe '.from_rgba_stream' do
    it "should load an image correctly from a datastream" do
      File.open(resource_file('pixelstream.rgba')) do |stream|
        matrix = ChunkyPNG::Canvas.from_rgba_stream(240, 180, stream)
        matrix.should == reference_canvas('pixelstream_reference')
      end
    end
  end
  
  describe '#to_rgba_stream' do
    before { File.open(resource_file('pixelstream.rgba'), 'rb') { |f| @reference_data = f.read } }
    
    it "should load an image correctly from a datastream" do
      reference_canvas('pixelstream_reference').to_rgba_stream.should == @reference_data
    end
  end

  describe '#to_rgb_stream' do
    before { File.open(resource_file('pixelstream.rgb'), 'rb') { |f| @reference_data = f.read } }
    
    it "should load an image correctly from a datastream" do
      reference_canvas('pixelstream_reference').to_rgb_stream.should == @reference_data
    end
  end
  
  describe '#size' do
    it "should return the dimensions as two-item array" do
      ChunkyPNG::Canvas.new(12, 34).size.should == [12, 34]
    end
  end
  
  describe '#include_xy?' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should return true if the coordinates are within bounds, false otherwise" do
      @canvas.include_xy?( 0,  0).should be_true
      
      @canvas.include_xy?(-1,  0).should be_false
      @canvas.include_xy?( 1,  0).should be_false
      @canvas.include_xy?( 0, -1).should be_false
      @canvas.include_xy?( 0,  1).should be_false
      @canvas.include_xy?(-1, -1).should be_false
      @canvas.include_xy?(-1,  1).should be_false
      @canvas.include_xy?( 1, -1).should be_false
      @canvas.include_xy?( 1,  1).should be_false
    end
  end
  
  describe '#include_x?' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should return true if the x-coordinate is within bounds, false otherwise" do
      @canvas.include_x?( 0).should be_true
      @canvas.include_x?(-1).should be_false
      @canvas.include_x?( 1).should be_false
    end
  end
  
  describe '#include_y?' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should return true if the y-coordinate is within bounds, false otherwise" do
      @canvas.include_y?( 0).should be_true
      @canvas.include_y?(-1).should be_false
      @canvas.include_y?( 1).should be_false
    end
  end
  
  describe '#assert_xy!' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should not raise an exception if the coordinates are within bounds" do
      @canvas.should_receive(:include_xy?).with(0, 0).and_return(true)
      lambda { @canvas.send(:assert_xy!, 0, 0) }.should_not raise_error
    end
    
    it "should raise an exception if the coordinates are out of bounds bounds" do
      @canvas.should_receive(:include_xy?).with(0, -1).and_return(false)
      lambda { @canvas.send(:assert_xy!, 0, -1) }.should raise_error(ChunkyPNG::OutOfBounds)
    end
  end
  
  describe '#assert_x!' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should not raise an exception if the x-coordinate is within bounds" do
      @canvas.should_receive(:include_x?).with(0).and_return(true)
      lambda { @canvas.send(:assert_x!, 0) }.should_not raise_error
    end
    
    it "should raise an exception if the x-coordinate is out of bounds bounds" do
      @canvas.should_receive(:include_y?).with(-1).and_return(false)
      lambda { @canvas.send(:assert_y!, -1) }.should raise_error(ChunkyPNG::OutOfBounds)
    end
  end
  
  describe '#[]' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::WHITE) }
    
    it "should return the pixel value if the coordinates are within bounds" do
      @canvas[0, 0].should == ChunkyPNG::Color::WHITE
    end
    
    it "should assert the coordinates to be within bounds" do
      @canvas.should_receive(:assert_xy!).with(0, 0)
      @canvas[0, 0]
    end
  end
  
  describe '#get_pixel' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::WHITE) }
    
    it "should return the pixel value if the coordinates are within bounds" do
      @canvas.get_pixel(0, 0).should == ChunkyPNG::Color::WHITE
    end
    
    it "should not assert nor check the coordinates" do
      @canvas.should_not_receive(:assert_xy!)
      @canvas.should_not_receive(:include_xy?)
      @canvas.get_pixel(0, 0)
    end
  end
  
  describe '#[]=' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should change the pixel's color value" do
      lambda { @canvas[0, 0] = ChunkyPNG::Color::BLACK }.should change { @canvas[0, 0] }.from(ChunkyPNG::Color::TRANSPARENT).to(ChunkyPNG::Color::BLACK)
    end
    
    it "should assert the bounds of the image" do
      @canvas.should_receive(:assert_xy!).with(0, 0)
      @canvas[0, 0] = ChunkyPNG::Color::BLACK
    end
  end
  
  describe 'set_pixel' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }

    it "should change the pixel's color value" do
      lambda { @canvas.set_pixel(0, 0, ChunkyPNG::Color::BLACK) }.should change { @canvas[0, 0] }.from(ChunkyPNG::Color::TRANSPARENT).to(ChunkyPNG::Color::BLACK)
    end
    
    it "should not assert or check the bounds of the image" do
      @canvas.should_not_receive(:assert_xy!)
      @canvas.should_not_receive(:include_xy?)
      @canvas.set_pixel(0, 0, ChunkyPNG::Color::BLACK)
    end
  end
  
  describe '#set_pixel_in_bounds' do
    before { @canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::TRANSPARENT) }
    
    it "should change the pixel's color value" do
      lambda { @canvas.set_pixel_in_bounds(0, 0, ChunkyPNG::Color::BLACK) }.should change { @canvas[0, 0] }.from(ChunkyPNG::Color::TRANSPARENT).to(ChunkyPNG::Color::BLACK)
    end

    it "should not assert, but only check the coordinates" do
      @canvas.should_not_receive(:assert_xy!)
      @canvas.should_receive(:include_xy?).with(0, 0)
      @canvas.set_pixel_in_bounds(0, 0, ChunkyPNG::Color::BLACK)
    end

    it "should do nothing if the coordinates are out of bounds" do
      @canvas.set_pixel_in_bounds(-1, 1, ChunkyPNG::Color::BLACK).should be_nil
      @canvas[0, 0].should == ChunkyPNG::Color::TRANSPARENT
    end
  end
  
  describe '#row' do
    before { @canvas = reference_canvas('operations') }

    it "should give an out of bounds exception when y-coordinate is out of bounds" do
      lambda { @canvas.row(-1) }.should raise_error(ChunkyPNG::OutOfBounds)
      lambda { @canvas.row(16) }.should raise_error(ChunkyPNG::OutOfBounds)
    end

    it "should return the correct pixels" do
      data = @canvas.row(0)
      data.should have(@canvas.width).items
      data.should == [65535, 268500991, 536936447, 805371903, 1073807359, 1342242815, 1610678271, 1879113727, 2147549183, 2415984639, 2684420095, 2952855551, 3221291007, 3489726463, 3758161919, 4026597375]
    end
  end
  
  describe '#column' do
    before { @canvas = reference_canvas('operations') }

    it "should give an out of bounds exception when x-coordinate is out of bounds" do
      lambda { @canvas.column(-1) }.should raise_error(ChunkyPNG::OutOfBounds)
      lambda { @canvas.column(16) }.should raise_error(ChunkyPNG::OutOfBounds)
    end

    it "should return the correct pixels" do
      data = @canvas.column(0)
      data.should have(@canvas.height).items
      data.should == [65535, 1114111, 2162687, 3211263, 4259839, 5308415, 6356991, 7405567, 8454143, 9502719, 10551295, 11599871, 12648447, 13697023, 14745599, 15794175]
    end
  end
end
