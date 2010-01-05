require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG::Image do

  it "should write a valid PNG image" do
    image    = ChunkyPNG::Image.new(10, 20)
    filename = resource_file('testing.png')
    File.open(filename, 'w') { |f| image.write(f) }
    
    
    png = ChunkyPNG.load(filename)
    png.header_chunk.width.should == 20
    png.header_chunk.height.should == 20
    png.data_chunks.should_not be_empty
    # `open #{filename}`
  end
end

