require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix do
  
  describe '.from_rgb_stream' do
    it "should load an image correctly from a datastrean" do
      File.open(resource_file('pixelstream.rgb')) do |stream|
        pm = ChunkyPNG::PixelMatrix.from_rgb_stream(240, 180, stream)
        pm.should == reference_matrix('pixelstream_reference')
      end
    end
  end

  describe '#crop' do
    before(:each) do
      @matrix = ChunkyPNG::PixelMatrix.from_file(resource_file('operations.png'))
    end

    it "should crop the right pixels from the original matrix" do
      cropped = @matrix.crop(10, 5, 4, 8)
      cropped.should == reference_matrix('cropped')
    end
  end

  describe '#compose' do
    before(:each) do
      @matrix = ChunkyPNG::PixelMatrix.from_file(resource_file('operations.png'))
    end

    it "should compose pixels correctly" do
      submatrix = ChunkyPNG::PixelMatrix.new(4, 8, ChunkyPNG::Color.rgba(0, 0, 0, 75))
      @matrix.compose(submatrix, 8, 4)
      @matrix.should == reference_matrix('composited')
    end
  end

  describe '#replace' do
    before(:each) do
      @matrix = ChunkyPNG::PixelMatrix.from_file(resource_file('operations.png'))
    end

    it "should replace the correct pixels" do
      submatrix = ChunkyPNG::PixelMatrix.new(3, 2, ChunkyPNG::Color.rgb(200, 255, 0))
      @matrix.replace(submatrix, 5, 4)
      @matrix.should == reference_matrix('replaced')
    end
  end
end
