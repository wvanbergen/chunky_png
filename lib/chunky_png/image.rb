module ChunkyPNG
  class Image
    
    attr_reader :pixels
    
    def initialize(width, height, background_color = ChunkyPNG::Color::WHITE)
      @pixels = ChunkyPNG::PixelMatrix.new(width, height, background_color)
    end
    
    def width
      pixels.width
    end
    
    def height
      pixels.height
    end
    
    def write(io)
      datastream = ChunkyPNG::Datastream.new
      datastream.header_chunk = ChunkyPNG::Chunk::Header.new(:width => width, :height => height)
      datastream.data_chunks  = datastream.idat_chunks(pixels.to_rgb_pixelstream)
      datastream.end_chunk    = ChunkyPNG::Chunk::End.new
      datastream.write(io)
    end
  end
end