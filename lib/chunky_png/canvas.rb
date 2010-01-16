module ChunkyPNG

  # The ChunkPNG::Canvas class represents a raster image as a matrix of
  # pixels. 
  #
  # This class supports loading a Canvas from a PNG datastream, and creating a
  # {ChunkyPNG::Datastream PNG datastream} based on this matrix. ChunkyPNG
  # only supports 8-bit color depth, otherwise all of the PNG format's
  # variations are supported for both reading and writing.
  #
  # This class offers per-pixel access to the matrix by using x,y coordinates.
  # It uses a palette (see {ChunkyPNG::Palette}) to keep track of the
  # different colors used in this matrix.
  #
  # The pixels in the canvas are stored as 4-byte fixnum, representing 32-bit
  # RGBA colors (8 bit per channel). The module {ChunkyPNG::Color} is provided
  # to work more easily with these number as color values.
  #
  # The module {ChunkyPNG::Canvas::Operations} is imported for operations on
  # the whole canvas, like cropping and alpha compositing. Simple drawing
  # functions are imported from the {ChunkyPNG::Canvas::Drawing} module.
  class Canvas

    include PNGEncoding
    extend  PNGDecoding
    extend  Adam7Interlacing

    include Operations
    include Drawing

    # @return [Integer] The number of columns in this canvas
    attr_reader :width

    # @return [Integer] The number of rows in this canvas
    attr_reader :height

    # @return [Array<ChunkyPNG::Color>] The list of pixels in this canvas.
    #     This array always should have +width * height+ elements.
    attr_reader :pixels

    # Initializes a new Canvas instance
    # @param [Integer] width The width in pixels of this canvas
    # @param [Integer] width The height in pixels of this canvas
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
        raise "Cannot use this value as initial canvas: #{initial.inspect}!"
      end
    end
    
    def initialize_copy(other)
      @width, @height = other.width, other.height
      @pixels = other.pixels.dup
    end

    # Returns the size ([width, height]) for this canvas.
    # @return Array An array with the width and height of this canvas as elements.
    def size
      [@width, @height]
    end

    # Replaces a single pixel in this canvas.
    # @param [Integer] x The x-coordinate of the pixel (column)
    # @param [Integer] y The y-coordinate of the pixel (row)
    # @param [ChunkyPNG::Color] pixel The new pixel for the provided coordinates.
    def []=(x, y, color)
      @pixels[y * width + x] = color
    end

    # Returns a single pixel from this canvas.
    # @param [Integer] x The x-coordinate of the pixel (column)
    # @param [Integer] y The y-coordinate of the pixel (row)
    # @return [ChunkyPNG::Color] The current pixel at the provided coordinates.
    def [](x, y)
      @pixels[y * width + x]
    end

    # Returns the palette used for this canvas.
    # @return [ChunkyPNG::Palette] A pallete which contains all the colors that are
    #    being used for this image.
    def palette
      ChunkyPNG::Palette.from_canvas(self)
    end

    # Equality check to compare this canvas with other matrices.
    # @param other The object to compare this Matrix to.
    # @return [true, false] True if the size and pixel values of the other canvas
    #    are exactly the same as this canvas's size and pixel values.
    def eql?(other)
      other.kind_of?(self.class) && other.pixels == self.pixels &&
            other.width == self.width && other.height == self.height
    end

    alias :== :eql?

    # Creates an ChunkyPNG::Image object from this canvas
    def to_image
      ChunkyPNG::Image.from_canvas(self)
    end

    #################################################################
    # CONSTRUCTORS
    #################################################################

    # Creates a new canvas instance by duplicating another instance.
    # @param [ChunkyPNG::Canvas] canvas The canvas to duplicate
    # @return [ChunkyPNG::Canvas] The newly constructed canvas instance.
    def self.from_canvas(canvas)
      self.new(canvas.width, canvas.height, canvas.pixels.dup)
    end

    # Creates a canvas by reading pixels from an RGB formatted stream with a
    # provided with and height. 
    #
    # Every pixel should be represented by 3 bytes in the stream, in the correct
    # RGB order. This format closely resembles the internal representation of a
    # canvas object, so this kind of stream can be read extremely quickly.
    #
    # @param [Integer] width The width of the new canvas.
    # @param [Integer] height The height of the new canvas.
    # @param [#read, String] stream The stream to read the pixel data from.
    # @return [ChunkyPNG::Canvas] The newly constructed canvas instance.
    def self.from_rgb_stream(width, height, stream)
      string = stream.respond_to?(:read) ? stream.read(3 * width * height) : stream.to_s[0, 3 * width * height]
      string << "\255" # Add a fourth byte to the last RGB triple.
      unpacker = 'NX' * (width * height)
      pixels = string.unpack(unpacker).map { |color| color | 0x000000ff }
      self.new(width, height, pixels)
    end

    # Creates a canvas by reading pixels from an RGBA formatted stream with a
    # provided with and height. 
    #
    # Every pixel should be represented by 4 bytes in the stream, in the correct
    # RGBA order. This format is exactly like the internal representation of a
    # canvas object, so this kind of stream can be read extremely quickly.
    #
    # @param [Integer] width The width of the new canvas. 
    # @param [Integer] height The height of the new canvas. 
    # @param [#read, String] stream The stream to read the pixel data from. 
    # @return [ChunkyPNG::Canvas] The newly constructed canvas instance.
    def self.from_rgba_stream(width, height, stream)
      string = stream.respond_to?(:read) ? stream.read(4 * width * height) : stream.to_s[0, 4 * width * height]
      self.new(width, height, string.unpack("N*"))
    end
    
    #################################################################
    # EXPORTING
    #################################################################
    
    # Creates an RGB-formatted pixelstream with the pixel data from this canvas.
    #
    # Note that this format is fast but bloated, because no compression is used
    # and the internal representation is left intact. However, to reconstruct the
    # canvas, the width and height should be known.
    #
    # @return [String] The RGBA-formatted pixel data.
    def to_rgba_stream
      pixels.pack('N*')
    end

    # Creates an RGB-formatted pixelstream with the pixel data from this canvas.
    #
    # Note that this format is fast but bloated, because no compression is used
    # and the internal representation is almost left intact. However, to reconstruct 
    # the canvas, the width and height should be known.
    #
    # @return [String] The RGB-formatted pixel data.
    def to_rgb_stream
      packer = 'NX' * (width * height)
      pixels.pack(packer)
    end
  end
end
