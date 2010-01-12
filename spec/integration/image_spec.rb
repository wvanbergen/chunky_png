require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::Image do

  it "should write a valid PNG image using an indexed palette" do
    image    = ChunkyPNG::Image.new(10, 20, ChunkyPNG::Pixel.rgb(10, 30, 130))
    filename = resource_file('testing.png')
    File.open(filename, 'w') { |f| image.write(f) }

    png = ChunkyPNG.load(filename)

    png.header_chunk.width.should  == 10
    png.header_chunk.height.should == 20
    png.header_chunk.color.should  == ChunkyPNG::Chunk::Header::COLOR_INDEXED
    png.palette_chunk.should_not be_nil
    png.data_chunks.should_not be_empty
    # `open #{filename}`
    
    File.unlink(filename)
  end
end

