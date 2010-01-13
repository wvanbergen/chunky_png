module ChunkyPNG
  
  # The ChunkPNG::PixelMatrix class represents a matrix of pixels of which an i
  # mage consists. This class supports loading a PixelMatrix from a PNG datastream,
  # and creating a PNG datastream bse don this matrix.
  #
  # This class offers per-pixel access to the matrix by using x,y coordinates. It uses
  # a palette (see {ChunkyPNG::Palette}) to keep track of the different colors used in
  # this matrix.
  #
  # @see ChunkyPNG::Datastream
  class PixelMatrix
    
    include Encoding
    extend  Decoding
    
    # @return [Integer] The number of columns in this pixel matrix
    attr_reader :width

    # @return [Integer] The number of rows in this pixel matrix
    attr_reader :height

    # @return [Array<ChunkyPNG::Pixel>] The list of pixels in this matrix.
    #     This array always should have +width * height+ elements.
    attr_reader :pixels

    # Initializes a new PixelMatrix instance
    # @param [Integer] width The width in pixels of this matrix
    # @param [Integer] width The height in pixels of this matrix
    # @param [ChunkyPNG::Pixel, Array<ChunkyPNG::Pixel>] initial The initial value of te pixels:
    #
    #    * If a color is passed to this parameter, this color will be used as background color. 
    #
    #    * If an array of pixels is provided, these pixels will be used as initial value. Note 
    #      that the amount of pixels in this array should equal +width * height+.
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
    
    # Replaces a single pixel in this matrix.
    # @param [Integer] x The x-coordinate of the pixel (column)
    # @param [Integer] y The y-coordinate of the pixel (row)
    # @param [ChunkyPNG::Pixel] pixel The new pixel for the provided coordinates.
    def []=(x, y, pixel)
      @pixels[y * width + x] = pixel
    end
    
    # Returns a single pixel from this matrix.
    # @param [Integer] x The x-coordinate of the pixel (column)
    # @param [Integer] y The y-coordinate of the pixel (row)
    # @return [ChunkyPNG::Pixel] The current pixel at the provided coordinates.
    def [](x, y)
      @pixels[y * width + x]
    end
    
    # Passes to this matrix of pixels line by line.
    # @yield [Array<ChunkyPNG::Pixel>] An line of pixels
    def each_scanline(&block)
      height.times do |i|
        scanline = @pixels[width * i, width]
        yield(scanline)
      end
    end
    
    # Returns the palette used for this pixel matrix.
    # @return [ChunkyPNG::Palette] A pallete which contains all the colors that are 
    #    being used for this image.
    def palette
      ChunkyPNG::Palette.from_pixels(@pixels)
    end
    
    # Converts this PixelMatrix to a datastream, so that it can be saved as a PNG image.
    # @param [Hash] constraints The constraints to use when encoding the matrix.
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
    
    # Equality check to compare this pixel matrix with other matrices.
    # @param other The object to compare this Matrix to.
    # @return [true, false] True if the size and pixel values of the other matrix
    #    are exactly the same as this matrix size and pixel values.
    def eql?(other)
      other.kind_of?(self.class) && other.pixels == self.pixels &&
            other.width == self.width && other.height == self.height
    end
    
    alias :== :eql?
  end
end
