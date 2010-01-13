module ChunkyPNG

  # The Pixel class represents a pixel, which has a single color. Within the
  # ChunkyPNG library, the concepts of pixels and colors are both used, and
  # they are both represented by the pixel class.
  #
  # Pixels/colors are represented in RGBA componetns. Each of the four components
  # is stored with a depth of 8 biths (maximum value = 255). Together, these
  # components are stored in a 4-bye Fixnum.
  #
  # A pixel will always be represented using these 4 components. When the image
  # is encoded, a more suitable representation can be used (e.g. rgb, grayscale,
  # palette-based), for which several conversion methods are provided.
  class Pixel

    # @return [Fixnum] The 4-byte fixnum representation of the pixel's
    #    color, where red compenent uses the most significant byte and the
    #    alpha component the least significant byte.
    attr_reader :value

    alias :to_i :value

    # Initalizes a new pixel instance. Usually, it is more convenient to
    # use one of the constructors below.
    # @param [Fixnum] value The 4-byte fixnum representation of the pixel's
    #    color, where red compenent uses the most significant byte and the
    #    alpha component the least significant byte.
    def initialize(value)
      @value = value.to_i
    end

    ####################################################################
    # PIXEL LOADING
    ####################################################################

    # Creates a new pixels using an r, g, b triple.
    # @return [ChunkyPNG::Pixel] The newly constructed pixel.
    def self.rgb(r, g, b, a = 255)
      rgba(r, g, b, a)
    end

    # Creates a new pixels using an r, g, b triple and an alpha value.
    # @return [ChunkyPNG::Pixel] The newly constructed pixel.
    def self.rgba(r, g, b, a)
      self.new(r << 24 | g << 16 | b << 8 | a)
    end

    # Creates a new pixels using a grayscale teint.
    # @return [ChunkyPNG::Pixel] The newly constructed pixel.
    def self.grayscale(teint, a = 255)
      rgba(teint, teint, teint, a)
    end

    # Creates a new pixels using a grayscale teint and alpha value.
    # @return [ChunkyPNG::Pixel] The newly constructed pixel.
    def self.grayscale_alpha(teint, a)
      rgba(teint, teint, teint, a)
    end

    # Creates a pixel by unpacking an rgb triple from a string
    # @return [ChunkyPNG::Pixel] The newly constructed pixel.
    def self.from_rgb_stream(stream)
      self.rgb(*stream.unpack('C3'))
    end

    # Creates a pixel by unpacking an rgba triple from a string
    # @return [ChunkyPNG::Pixel] The newly constructed pixel.
    def self.from_rgba_stream(stream)
      self.rgba(*stream.unpack('C4'))
    end

    ####################################################################
    # COLOR CONSTANTS
    ####################################################################

    # Black pixel/color
    BLACK = rgb(  0,   0,   0)

    # White pixel/color
    WHITE = rgb(255, 255, 255)

    # Fully transparent pixel/color
    TRANSPARENT = rgba(0, 0, 0, 0)

    ####################################################################
    # PROPERTIES
    ####################################################################

    # Returns the red-component from the pixel value.
    # @return [Fixnum] A value between 0 and 255.
    def r
      (@value & 0xff000000) >> 24
    end

    # Returns the green-component from the pixel value.
    # @return [Fixnum] A value between 0 and 255.
    def g
      (@value & 0x00ff0000) >> 16
    end

    # Returns the blue-component from the pixel value.
    # @return [Fixnum] A value between 0 and 255.
    def b
      (@value & 0x0000ff00) >> 8
    end

    # Returns the alpha channel value for the pixel.
    # @return [Fixnum] A value between 0 and 255.
    def a
      @value & 0x000000ff
    end

    # Returns true if this pixel is fully opaque.
    # @return [true, false] True if the alpha channel equals 255.
    def opaque?
      a == 0x000000ff
    end

    # Returns true if this pixel is fully transparent.
    # @return [true, false] True if the alpha channel equals 0.
    def fully_transparent?
      a == 0x000000ff
    end

    # Returns true if this pixel is fully transparent.
    # @return [true, false] True if the r, g and b component are equal.
    def grayscale?
      r == g && r == b
    end

    ####################################################################
    # COMPARISON
    ####################################################################

    # Returns a nice string representation for this pixel using hex notation.
    # @return [String]
    def inspect
      '#%08x' % @value
    end

    # Returns a hash for determining the uniqueness of a pixel.
    # @return [Fixnum] The hash of the fixnum that is representing this pixel.
    def hash
      @value.hash
    end

    # Checks whether to pixels are the same (i.e. have the same color).
    # @param [Object] other The object to compare this pixel with.
    # @return [true, false] Returns true iff the pixels' fixnum representations are the same.
    def eql?(other)
      other.to_i == self.to_i
    end

    alias :== :eql?

    # Compares to pixels for ordering, using the pixels' fixnum representations.
    # @param [Object] other The object to compare this pixel with.
    # @return [Fixnum] A number used for sorting.
    def <=>(other)
      other.value <=> self.value
    end

    ####################################################################
    # CONVERSIONS
    ####################################################################

    # Convert this pixel to a 4-tuple, containing r,g,b and a values.
    # @return [Array<Fixnum>] An array with 4 color components.
    def to_truecolor_alpha_bytes
      [r,g,b,a]
    end

    # Convert this pixel to a triple, containing r,g, and b values.
    # @return [Array<Fixnum>] An array with 3 color components.
    def to_truecolor_bytes
      [r,g,b]
    end

    # Convert this pixel to an array with the color index in the palette.
    # @return [Array<Fixnum>] An array with 1 color index.
    def to_indexed_bytes(palette)
      [index(palette)]
    end

    # Convert this grayscale pixel to a 1-element array with the grayscale teint.
    # @return [Array<Fixnum>] An array with 1 grayscale teint as element.
    def to_grayscale_bytes
      [r] # Assumption: r == g == b
    end

    # Convert this grayscale pixel to a 2-element array with the grayscale teint
    # and the alpha value.
    # @return [Array<Fixnum>] An array with 2 value, the teint and the alpha value.
    def to_grayscale_alpha_bytes
      [r, a] # Assumption: r == g == b
    end

    ####################################################################
    # ALPHA COMPOSITION
    ####################################################################

    # Multiplies two fractions using integer math, where the fractions are stored using an
    # integer between 0 and 255. This method is used as a helper method for compositing
    # pixels when using integer math.
    #
    # @param [Fixnum] a The first fraction.
    # @param [Fixnum] b The second fraction.
    # @return [Fixnum] The result of the multiplication.
    def int8_mult(a, b)
      t = a * b + 0x80
      ((t >> 8) + t) >> 8
    end

    # Composes two pixels with an alpha channel using integer math.
    #
    # The pixel instance is used as background color, the pixel provided as +other+
    # parameter is used as foreground pixel in the composition formula.
    #
    # This version is faster than the version based on floating point math, so this
    # compositing function is used by default.
    #
    # @param [ChunkyPNG::Pixel] other The foreground pixel to compose with.
    # @return [ChunkyPNG::Pixel] The composited pixel.
    # @see ChunkyPNG::Pixel#compose_precise
    def compose_quick(other)
      if other.a    == 0xff
        other
      elsif other.a == 0x00
        self
      else
        a_com = int8_mult(0xff - other.a, a)
        new_r = int8_mult(other.a, other.r) + int8_mult(a_com, r)
        new_g = int8_mult(other.a, other.g) + int8_mult(a_com, g)
        new_b = int8_mult(other.a, other.b) + int8_mult(a_com, b)
        new_a = other.a + a_com
        ChunkyPNG::Pixel.rgba(new_r, new_g, new_b, new_a)
      end
    end

    # Composes two pixels with an alpha channel using floating point math.
    #
    # The pixel instance is used as background color, the pixel provided as +other+
    # parameter is used as foreground pixel in the composition formula.
    #
    # This method uses more precise floating point math, but this precision is lost
    # when the result is converted back to an integer. Because it is slower than
    # the version based on integer math, that version is preferred.
    #
    # @param [ChunkyPNG::Pixel] other The foreground pixel to compose with.
    # @return [ChunkyPNG::Pixel] The composited pixel.
    # @see ChunkyPNG::Pixel#compose_quick
    def compose_precise(other)
      if other.a == 255
        other
      elsif other.a == 0
        self
      else
        alpha       = other.a / 255.0
        other_alpha = a / 255.0
        alpha_com   = (1.0 - alpha) * other_alpha

        new_r = (alpha * other.r + alpha_com * r).round
        new_g = (alpha * other.g + alpha_com * g).round
        new_b = (alpha * other.b + alpha_com * b).round
        new_a = ((alpha + alpha_com) * 255).round
        ChunkyPNG::Pixel.rgba(new_r, new_g, new_b, new_a)
      end
    end

    alias :compose :compose_quick
    alias :& :compose

    ####################################################################
    # STATIC UTILITY METHODS
    ####################################################################

    # Returns the size in bytes of a pixel whe it is stored using a given color mode.
    # @param [Fixnum] color_mode The color mode in which the pixels are stored.
    # @return [Fixnum] The number of bytes used per pixel in a datastream.
    def self.bytesize(color_mode)
      case color_mode
        when ChunkyPNG::COLOR_INDEXED         then 1
        when ChunkyPNG::COLOR_TRUECOLOR       then 3
        when ChunkyPNG::COLOR_TRUECOLOR_ALPHA then 4
        when ChunkyPNG::COLOR_GRAYSCALE       then 1
        when ChunkyPNG::COLOR_GRAYSCALE_ALPHA then 2
        else raise "Don't know the bytesize of pixels in this colormode: #{color_mode}!"
      end
    end
  end
end
