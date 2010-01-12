module ChunkyPNG
  
  class PixelMatrix
    
    include Encoding
    extend  Decoding
    
    FILTER_NONE    = 0
    FILTER_SUB     = 1
    FILTER_UP      = 2
    FILTER_AVERAGE = 3
    FILTER_PAETH   = 4
    
    attr_reader :width, :height, :pixels


    def initialize(width, height, initial = ChunkyPNG::Pixel::TRANSPARENT)
      
      @width, @height = width, height
      
      if initial.kind_of?(ChunkyPNG::Pixel)
        @pixels = Array.new(width * height, initial)
      elsif initial.kind_of?(Array) && initial.size == width * height
        @pixels = initial
      else 
        raise "Cannot use this value as initial pixel matrix: #{initial.inspect}!"
      end
    end
    
    def []=(x, y, pixel)
      @pixels[y * width + x] = pixel
    end
    
    def [](x, y)
      @pixels[y * width + x]
    end
    
    def each_scanline(&block)
      height.times do |i|
        scanline = @pixels[width * i, width]
        yield(scanline)
      end
    end
    
    def palette
      ChunkyPNG::Palette.from_pixels(@pixels)
    end
    
    def opaque?
      pixels.all? { |pixel| pixel.opaque? }
    end
    
    def indexable?
      palette.indexable?
    end
    
    def to_datastream(constraints = {})
      data = encode(constraints)
      ds = Datastream.new
      ds.header_chunk       = Chunk::Header.new(data[:header])
      ds.palette_chunk      = data[:palette_chunk]      if data[:palette_chunk]
      ds.transparency_chunk = data[:transparency_chunk] if data[:transparency_chunk]
      ds.data_chunks        = ds.idat_chunks(data[:pixelstream])
      ds.end_chunk          = Chunk::End.new
      return ds
    end
    
    def eql?(other)
      other.kind_of?(self.class) && other.pixels == self.pixels &&
            other.width == self.width && other.height == self.height
    end
    
    alias :== :eql?
  end
end
