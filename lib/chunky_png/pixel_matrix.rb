module ChunkyPNG

  # The ChunkPNG::PixelMatrix class represents a matrix of pixels of which an
  # image consists. This class supports loading a PixelMatrix from a PNG datastream,
  # and creating a PNG datastream bse don this matrix.
  #
  # This class offers per-pixel access to the matrix by using x,y coordinates. It uses
  # a palette (see {ChunkyPNG::Palette}) to keep track of the different colors used in
  # this matrix.
  #
  # The pixels in the matrix are stored as 4-byte fixnums. When accessing these pixels,
  # these Fixnums are wrapped in a {ChunkyPNG::Pixel} instance to simplify working with them.
  #
  # @see ChunkyPNG::Datastream
  class PixelMatrix

    include PNGEncoding
    extend  PNGDecoding
    extend  Adam7Interlacing

    include Operations
    include Drawing

    # @return [Integer] The number of columns in this pixel matrix
    attr_reader :width

    # @return [Integer] The number of rows in this pixel matrix
    attr_reader :height

    # @return [Array<ChunkyPNG::Color>] The list of pixels in this matrix.
    #     This array always should have +width * height+ elements.
    attr_reader :pixels

    # Initializes a new PixelMatrix instance
    # @param [Integer] width The width in pixels of this matrix
    # @param [Integer] width The height in pixels of this matrix
    # @param [ChunkyPNG::Pixel, Array<ChunkyPNG::Color>] initial The initial value of te pixels:
    #
    #    * If a color is passed to this parameter, this color will be used as background color.
    #
    #    * If an array of pixels is provided, these pixels will be used as initial value. Note
    #      that the amount of pixels in this array should equal +width * height+.
    def initialize(width, height, initial = ChunkyPNG::Color::TRANSPARENT)

      @width, @height = width, height

      if initial.kind_of?(Fixnum)
        @pixels = Array.new(width * height, initial)
      elsif initial.kind_of?(Array) && initial.size == width * height
        @pixels = initial.map(&:to_i)
      else
        raise "Cannot use this value as initial pixel matrix: #{initial.inspect}!"
      end
    end
    
    def initialize_copy(other)
      @width, @height = other.width, other.height
      @pixels = other.pixels.dup
    end

    # Returns the size ([width, height]) for this matrix.
    # @return Array An array with the width and height of this matrix as elements.
    def size
      [@width, @height]
    end

    # Replaces a single pixel in this matrix.
    # @param [Integer] x The x-coordinate of the pixel (column)
    # @param [Integer] y The y-coordinate of the pixel (row)
    # @param [ChunkyPNG::Color] pixel The new pixel for the provided coordinates.
    def []=(x, y, color)
      @pixels[y * width + x] = color
    end

    # Returns a single pixel from this matrix.
    # @param [Integer] x The x-coordinate of the pixel (column)
    # @param [Integer] y The y-coordinate of the pixel (row)
    # @return [ChunkyPNG::Color] The current pixel at the provided coordinates.
    def [](x, y)
      @pixels[y * width + x]
    end

    # Returns the palette used for this pixel matrix.
    # @return [ChunkyPNG::Palette] A pallete which contains all the colors that are
    #    being used for this image.
    def palette
      ChunkyPNG::Palette.from_pixel_matrix(self)
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

    # Creates an ChunkyPNG::Image object from this pixel matrix
    def to_image
      ChunkyPNG::Image.from_pixel_matrix(self)
    end

    #################################################################
    # CONSTRUCTORS
    #################################################################

    def self.from_pixel_matrix(matrix)
      self.new(matrix.width, matrix.height, matrix.pixels.dup)
    end

    def self.from_rgb_stream(width, height, stream)
      pixels = []
      while pixeldata = stream.read(3)
        pixels << ChunkyPNG::Color.from_rgb_stream(pixeldata)
      end
      self.new(width, height, pixels)
    end

    def self.from_rgba_stream(width, height, stream)
      pixels = []
      while pixeldata = stream.read(4)
        pixels << ChunkyPNG::Color.from_rgba_stream(pixeldata)
      end
      self.new(width, height, pixels)
    end
  end
end
