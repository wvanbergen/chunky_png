require 'spec_helper'

require 'chunky_png/rmagick'

describe ChunkyPNG::RMagick do
  
  it "should import an image from RMagick correctly" do
    image = Magick::Image.read(resource_file('16x16_non_interlaced.png')).first
    canvas = ChunkyPNG::RMagick.import(image)
    canvas.should == reference_canvas('16x16_non_interlaced')
  end
  
  it "should export an image to RMagick correctly" do
    canvas = reference_canvas('16x16_non_interlaced')
    image  = ChunkyPNG::RMagick.export(canvas)
  
    filename = resource_file('_rmagick.png')
    image.write("png:#{filename}") { |info| info.depth = 8 }
    canvas.should == ChunkyPNG::Canvas.from_file(filename)
  end
end