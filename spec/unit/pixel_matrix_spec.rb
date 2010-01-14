require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::PixelMatrix do

  describe '.from_rgb_stream' do
    it "should load an image correctly from a datastrean" do
      reference = ChunkyPNG.load(resource_file('pixelstream_reference.png')).pixel_matrix

      File.open(resource_file('pixelstream.rgb')) do |stream|
        pm = ChunkyPNG::PixelMatrix.from_rgb_stream(240, 180, stream)
        pm.should == reference
      end
    end
  end

  describe '.decode' do

    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should decode an image with color mode #{color_mode} correctly" do
        reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
        ds = ChunkyPNG.load(resource_file("gray_10x10_#{color_mode}.png"))
        ds.pixel_matrix.should == reference
      end
    end

    it "should decode a transparent image correctly" do
      reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Color.rgba(100, 100, 100, 128))
      ds = ChunkyPNG.load(resource_file("transparent_gray_10x10.png"))
      ds.pixel_matrix.should == reference
    end

    it "should decode an interlaced image correctly" do
      ds_i  = ChunkyPNG.load(resource_file("16x16_interlaced.png"))
      ds_ni = ChunkyPNG.load(resource_file("16x16_non_interlaced.png"))
      ds_i.pixel_matrix.should == ds_ni.pixel_matrix
    end
  end

  describe '.encode' do
    before(:each) do
      @reference = ChunkyPNG::PixelMatrix.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
    end

    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
      it "should encode an image with color mode #{color_mode} correctly" do

        filename = resource_file("_tmp_#{color_mode}.png")
        File.open(filename, 'w') { |f| @reference.to_datastream.write(f) }

        ChunkyPNG.load(filename).pixel_matrix.should == @reference

        File.unlink(filename)
      end
    end
  end

  describe '#crop' do
    before(:each) do
      @matrix = ChunkyPNG.load(resource_file('operations.png')).pixel_matrix
    end

    it "should crop the right pixels from the original matrix" do
      cropped = @matrix.crop(10, 5, 2, 3)
      cropped.size.should == [2, 3]
      ChunkyPNG::Color.r(cropped[0, 0]).should == 10 * 16
      ChunkyPNG::Color.g(cropped[0, 0]).should ==  5 * 16
    end
  end

  describe '#compose' do
    before(:each) do
      @matrix = ChunkyPNG.load(resource_file('operations.png')).pixel_matrix
    end

    it "should compose pixels correctly" do
      submatrix = ChunkyPNG::PixelMatrix.new(4, 8, ChunkyPNG::Color.rgba(0, 0, 0, 75))
      @matrix.compose(submatrix, 8, 4)
      display(@matrix)
    end
  end

  describe '#replace' do
    before(:each) do
      @matrix = ChunkyPNG.load(resource_file('operations.png')).pixel_matrix
    end

    it "should replace the correct pixels" do
      submatrix = ChunkyPNG::PixelMatrix.new(3, 2, ChunkyPNG::Color.rgb(255, 255, 0))
      @matrix.replace(submatrix, 5, 4)
      # display(@matrix)
    end
  end
end
