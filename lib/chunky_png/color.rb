module ChunkyPNG

  # The Color module defines methods for handling colors. Within the ChunkyPNG
  # library, the concepts of pixels and colors are both used, and they are
  # both represented by a Fixnum.
  #
  # Pixels/colors are represented in RGBA componetns. Each of the four
  # components is stored with a depth of 8 bits (maximum value = 255).
  # Together, these components are stored in a 4-byte Fixnum.
  #
  # A color will always be represented using these 4 components in memory.
  # When the image is encoded, a more suitable representation can be used
  # (e.g. rgb, grayscale, palette-based), for which several conversion methods
  # are provided in this module.
  module Color
    extend self

    ####################################################################
    # COLOR LOADING
    ####################################################################

    # Creates a new color using an r, g, b triple and an alpha value.
    # @return [Fixnum] The newly constructed color value.
    def rgba(r, g, b, a)
      r << 24 | g << 16 | b << 8 | a
    end

    # Creates a new color using an r, g, b triple.
    # @return [Fixnum] The newly constructed color value.
    def rgb(r, g, b, a = 255)
      rgba(r, g, b, a)
    end

    # Creates a new color using a grayscale teint.
    # @return [ChunkyPNG::Color] The newly constructed color value.
    def grayscale(teint, a = 255)
      rgba(teint, teint, teint, a)
    end

    # Creates a new color using a grayscale teint and alpha value.
    # @return [Fixnum] The newly constructed color value.
    def grayscale_alpha(teint, a)
      rgba(teint, teint, teint, a)
    end

    # Creates a color by unpacking an rgb triple from a string
    # @return [Fixnum] The newly constructed color value.
    def from_rgb_stream(stream)
      rgb(*stream.unpack('C3'))
    end

    # Creates a color by unpacking an rgba triple from a string
    # @return [Fixnum] The newly constructed color value.
    def from_rgba_stream(stream)
      rgba(*stream.unpack('C4'))
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

    # Returns the red-component from the color value.
    # @param [Fixnum] value The color value.
    # @return [Fixnum] A value between 0 and 255.
    def r(value)
      (value & 0xff000000) >> 24
    end
    
    # Returns the green-component from the color value.
    # @param [Fixnum] value The color value.
    # @return [Fixnum] A value between 0 and 255.
    def g(value)
      (value & 0x00ff0000) >> 16
    end
    
    # Returns the blue-component from the color value.
    # @param [Fixnum] value The color value.
    # @return [Fixnum] A value between 0 and 255.
    def b(value)
      (value & 0x0000ff00) >> 8
    end
    
    # Returns the alpha channel value for the color value.
    # @param [Fixnum] value The color value.
    # @return [Fixnum] A value between 0 and 255.
    def a(value)
      value & 0x000000ff
    end
    
    # Returns true if this color is fully opaque.
    # @param [Fixnum] value The color to test.
    # @return [true, false] True if the alpha channel equals 255.
    def opaque?(value)
      a(value) == 0x000000ff
    end
    
    # Returns true if this color is fully transparent.
    # @param [Fixnum] value The color to test.
    # @return [true, false] True if the r, g and b component are equal.
    def grayscale?(value)
      r(value) == b(value) && b(value) == g(value)
    end
    
    # Returns true if this color is fully transparent.
    # @param [Fixnum] value The color to test.
    # @return [true, false] True if the alpha channel equals 0.
    def fully_transparent?(value)
      a(value) == 0x00000000
    end
    
    ####################################################################
    # CONVERSIONS
    ####################################################################
      
    def hex(value)
      '#%08x' % @value
    end
    
    def truecolor_alpha_bytes(value)
      [r(value), g(value), b(value), a(value)]
    end
    
    def truecolor_bytes(value)
      [r(value), g(value), b(value)]
    end
    
    def grayscale_bytes(value)
      [r(value)] # assumption r == g == b
    end
    
    def grayscale_alpha_bytes(value)
      [r(value), a(value)] # assumption r == g == b
    end
    
    ####################################################################
    # ALPHA COMPOSITION
    ####################################################################

    # Multiplies two fractions using integer math, where the fractions are stored using an
    # integer between 0 and 255. This method is used as a helper method for compositing
    # colors using integer math.
    #
    # @param [Fixnum] a The first fraction.
    # @param [Fixnum] b The second fraction.
    # @return [Fixnum] The result of the multiplication.
    def int8_mult(a, b)
      t = a * b + 0x80
      ((t >> 8) + t) >> 8
    end

    # Composes two colors with an alpha channel using integer math.
    #
    # This version is faster than the version based on floating point math, so this
    # compositing function is used by default.
    #
    # @param [Fixnum] fg The foreground color.
    # @param [Fixnum] bg The foreground color.
    # @return [Fixnum] The composited color.
    # @see ChunkyPNG::Color#compose_precise
    def compose_quick(fg, bg)
      return fg if opaque?(fg)
      return bg if fully_transparent?(fg)
      
      a_com = int8_mult(0xff - a(fg), a(bg))
      new_r = int8_mult(a(fg), r(fg)) + int8_mult(a_com, r(bg))
      new_g = int8_mult(a(fg), g(fg)) + int8_mult(a_com, g(bg))
      new_b = int8_mult(a(fg), b(fg)) + int8_mult(a_com, b(bg))
      new_a = a(fg) + a_com
      rgba(new_r, new_g, new_b, new_a)
    end

    # Composes two colors with an alpha channel using floating point math.
    #
    # This method uses more precise floating point math, but this precision is lost
    # when the result is converted back to an integer. Because it is slower than
    # the version based on integer math, that version is preferred.
    #
    # @param [Fixnum] fg The foreground color.
    # @param [Fixnum] bg The foreground color.
    # @return [Fixnum] The composited color.
    # @see ChunkyPNG::Color#compose_quick
    def compose_precise(fg, bg)
      return fg if opaque?(fg)
      return bg if fully_transparent?(fg)
      
      fg_a  = a(fg) / 255.0
      bg_a  = a(bg) / 255.0
      a_com = (1.0 - fg_a) * bg_a

      new_r = (fg_a * r(fg) + a_com * r(bg)).round
      new_g = (fg_a * g(fg) + a_com * g(bg)).round
      new_b = (fg_a * b(fg) + a_com * b(bg)).round
      new_a = ((fg_a + a_com) * 255).round
      rgba(new_r, new_g, new_b, new_a)
    end

    alias :compose :compose_quick
    
    ####################################################################
    # STATIC UTILITY METHODS
    ####################################################################

    # Returns the size in bytes of a pixel when it is stored using a given color mode.
    # @param [Fixnum] color_mode The color mode in which the pixels are stored.
    # @return [Fixnum] The number of bytes used per pixel in a datastream.
    def bytesize(color_mode)
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
