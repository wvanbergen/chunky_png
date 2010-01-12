module ChunkyPNG
  class Image
    
    attr_reader :pixels
    
    def initialize(width, height, background_color = ChunkyPNG::Pixel::TRANSPARENT)
      @pixels = ChunkyPNG::PixelMatrix.new(width, height, background_color)
    end
    
    def width
      pixels.width
    end
    
    def height
      pixels.height
    end
    
    def write(io, constraints = {})
      datastream = pixels.to_datastream(constraints)
      datastream.write(io)
    end
  end
end