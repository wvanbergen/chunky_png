require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::Canvas do
  
  describe '.from_rgb_stream' do
    it "should load an image correctly from a datastrean" do
      File.open(resource_file('pixelstream.rgb')) do |stream|
        pm = ChunkyPNG::Canvas.from_rgb_stream(240, 180, stream)
        pm.should == reference_canvas('pixelstream_reference')
      end
    end
  end

  describe '#crop' do
    before(:each) do
      @canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
    end

    it "should crop the right pixels from the original canvas" do
      cropped = @canvas.crop(10, 5, 4, 8)
      cropped.should == reference_canvas('cropped')
    end
  end

  describe '#compose' do
    before(:each) do
      @canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
    end

    it "should compose pixels correctly" do
      subcanvas = ChunkyPNG::Canvas.new(4, 8, ChunkyPNG::Color.rgba(0, 0, 0, 75))
      @canvas.compose(subcanvas, 8, 4)
      @canvas.should == reference_canvas('composited')
    end
  end

  describe '#replace' do
    before(:each) do
      @canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
    end

    it "should replace the correct pixels" do
      subcanvas = ChunkyPNG::Canvas.new(3, 2, ChunkyPNG::Color.rgb(200, 255, 0))
      @canvas.replace(subcanvas, 5, 4)
      @canvas.should == reference_canvas('replaced')
    end
  end
end
