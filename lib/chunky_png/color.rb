module ChunkyPNG

  # The Color module defines methods for handling colors. Within the ChunkyPNG
  # library, the concepts of pixels and colors are both used, and they are
  # both represented by a Integer.
  #
  # Pixels/colors are represented in RGBA componetns. Each of the four
  # components is stored with a depth of 8 bits (maximum value = 255 =
  # {ChunkyPNG::Color::MAX}). Together, these components are stored in a 4-byte
  # Integer.
  #
  # A color will always be represented using these 4 components in memory.
  # When the image is encoded, a more suitable representation can be used
  # (e.g. rgb, grayscale, palette-based), for which several conversion methods
  # are provided in this module.
  module Color
    extend self

    # The maximum value of each color component.
    MAX = 0xff

    ####################################################################
    # CONSTRUCTING COLOR VALUES
    ####################################################################

    # Creates a new color using an r, g, b triple and an alpha value.
    # @return [Integer] The newly constructed color value.
    def rgba(r, g, b, a)
      r << 24 | g << 16 | b << 8 | a
    end

    # Creates a new color using an r, g, b triple.
    # @return [Integer] The newly constructed color value.
    def rgb(r, g, b)
      r << 24 | g << 16 | b << 8 | 0xff
    end

    # Creates a new color using a grayscale teint.
    # @return [ChunkyPNG::Color] The newly constructed color value.
    def grayscale(teint)
      teint << 24 | teint << 16 | teint << 8 | 0xff
    end

    # Creates a new color using a grayscale teint and alpha value.
    # @return [Integer] The newly constructed color value.
    def grayscale_alpha(teint, a)
      teint << 24 | teint << 16 | teint << 8 | a
    end

    ####################################################################
    # COLOR IMPORTING
    ####################################################################

    # Creates a color by unpacking an rgb triple from a string.
    #
    # @param [String] stream The string to load the color from. It should be 
    #     at least 3 + pos bytes long.
    # @param [Integer] pos The position in the string to load the triple from.
    # @return [Integer] The newly constructed color value.
    def from_rgb_stream(stream, pos = 0)
      rgb(*stream.unpack("@#{pos}C3"))
    end

    # Creates a color by unpacking an rgba triple from a string
    #
    # @param [String] stream The string to load the color from. It should be 
    #      at least 4 + pos bytes long.
    # @param [Integer] pos The position in the string to load the triple from.
    # @return [Integer] The newly constructed color value.
    def from_rgba_stream(stream, pos = 0)
      rgba(*stream.unpack("@#{pos}C4"))
    end
    
    # Creates a color by converting it from a string in hex notation. 
    #
    # It supports colors with (#rrggbbaa) or without (#rrggbb) alpha channel.
    # Color strings may include the prefix "0x" or "#".
    #
    # @param [String] str The color in hex notation. @return [Integer] The
    # converted color value.
    def from_hex(str)
      case str
        when /^(?:#|0x)?([0-9a-f]{6})$/i; ($1.hex << 8) | 0xff
        when /^(?:#|0x)?([0-9a-f]{8})$/i; $1.hex
        else raise ChunkyPNG::ExpectationFailed, "Not a valid hex color notation: #{str.inspect}!"
      end
    end

    ####################################################################
    # PROPERTIES
    ####################################################################

    # Returns the red-component from the color value.
    #
    # @param [Integer] value The color value.
    # @return [Integer] A value between 0 and MAX.
    def r(value)
      (value & 0xff000000) >> 24
    end
    
    # Returns the green-component from the color value.
    #
    # @param [Integer] value The color value.
    # @return [Integer] A value between 0 and MAX.
    def g(value)
      (value & 0x00ff0000) >> 16
    end
    
    # Returns the blue-component from the color value.
    #
    # @param [Integer] value The color value.
    # @return [Integer] A value between 0 and MAX.
    def b(value)
      (value & 0x0000ff00) >> 8
    end
    
    # Returns the alpha channel value for the color value.
    #
    # @param [Integer] value The color value.
    # @return [Integer] A value between 0 and MAX.
    def a(value)
      value & 0x000000ff
    end
    
    # Returns true if this color is fully opaque.
    #
    # @param [Integer] value The color to test.
    # @return [true, false] True if the alpha channel equals MAX.
    def opaque?(value)
      a(value) == 0x000000ff
    end
    
    # Returns the opaque value of this color by removing the alpha channel.
    # @param [Integer] value The color to transform.
    # @return [Integer] The opauq color
    def opaque!(value)
      value | 0x000000ff
    end
    
    # Returns true if this color is fully transparent.
    #
    # @param [Integer] value The color to test.
    # @return [true, false] True if the r, g and b component are equal.
    def grayscale?(value)
      r(value) == b(value) && b(value) == g(value)
    end
    
    # Returns true if this color is fully transparent.
    #
    # @param [Integer] value The color to test.
    # @return [true, false] True if the alpha channel equals 0.
    def fully_transparent?(value)
      a(value) == 0x00000000
    end

    ####################################################################
    # ALPHA COMPOSITION
    ####################################################################

    # Multiplies two fractions using integer math, where the fractions are stored using an
    # integer between 0 and 255. This method is used as a helper method for compositing
    # colors using integer math.
    #
    # This is a quicker implementation of ((a * b) / 255.0).round.
    #
    # @param [Integer] a The first fraction.
    # @param [Integer] b The second fraction.
    # @return [Integer] The result of the multiplication.
    def int8_mult(a, b)
      t = a * b + 0x80
      ((t >> 8) + t) >> 8
    end

    # Composes two colors with an alpha channel using integer math.
    #
    # This version is faster than the version based on floating point math, so this
    # compositing function is used by default.
    #
    # @param [Integer] fg The foreground color.
    # @param [Integer] bg The foreground color.
    # @return [Integer] The composited color.
    # @see ChunkyPNG::Color#compose_precise
    def compose_quick(fg, bg)
      return fg if opaque?(fg) || fully_transparent?(bg)
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
    # @param [Integer] fg The foreground color.
    # @param [Integer] bg The foreground color.
    # @return [Integer] The composited color.
    # @see ChunkyPNG::Color#compose_quick
    def compose_precise(fg, bg)
      return fg if opaque?(fg) || fully_transparent?(bg)
      return bg if fully_transparent?(fg)
      
      fg_a  = a(fg).to_f / MAX
      bg_a  = a(bg).to_f / MAX
      a_com = (1.0 - fg_a) * bg_a

      new_r = (fg_a * r(fg) + a_com * r(bg)).round
      new_g = (fg_a * g(fg) + a_com * g(bg)).round
      new_b = (fg_a * b(fg) + a_com * b(bg)).round
      new_a = ((fg_a + a_com) * MAX).round
      rgba(new_r, new_g, new_b, new_a)
    end

    alias :compose :compose_quick
    
    # Blends the foreground and background color by taking the average of 
    # the components.
    #
    # @param [Integer] fg The foreground color.
    # @param [Integer] bg The foreground color.
    # @return [Integer] The blended color.
    def blend(fg, bg)
      (fg + bg) >> 1
    end

    # Lowers the intensity of a color, by lowering its alpha by a given factor.
    # @param [Integer] color The color to adjust.
    # @param [Integer] factor Fade factor as an integer between 0 and 255.
    # @return [Integer] The faded color.
    def fade(color, factor)
      new_alpha = int8_mult(a(color), factor)
      (color & 0xffffff00) | new_alpha
    end
    
    # Decomposes a color, given a color, a mask color and a background color.
    # The returned color will be a variant of the mask color, with the alpha
    # channel set to the best fitting value. This basically is the reverse 
    # operation if alpha composition.
    #
    # If the color cannot be decomposed, this method will return the fully
    # transparentvariant of the mask color.
    #
    # @param [Integer] color The color that was the result of compositing.
    # @param [Integer] mask The opaque variant of the color that was being composed
    # @param [Integer] bg The background color on which the color was composed.
    # @param [Integer] tolerance The decomposition tolerance level, a value between 0 and 255.
    # @return [Integer] The decomposed color,a variant of the masked color with the 
    #    alpha channel set to an appropriate value.
    def decompose_color(color, mask, bg, tolerance = 1)
      if alpha_decomposable?(color, mask, bg, tolerance)
        mask & 0xffffff00 | decompose_alpha(color, mask, bg)
      else
        mask & 0xffffff00
      end
    end
    
    # Checks whether an alpha channel value can successfully be composed
    # given the resulting color, the mask color and a background color,
    # all of which should be opaque. 
    #
    # @param [Integer] color The color that was the result of compositing.
    # @param [Integer] mask The opauqe variant of the color that was being composed
    # @param [Integer] bg The background color on which the color was composed.
    # @param [Integer] tolerance The decomposition tolerance level, a value between 0 and 255.
    # @return [Integer] The decomposed alpha channel value, between 0 and 255.
    # @see #decompose_alpha
    def alpha_decomposable?(color, mask, bg, tolerance = 1)
      components = decompose_alpha_components(color, mask, bg)
      sum = components.inject(0) { |a,b| a + b } 
      max = components.max * 3
      return components.max <= 255 && components.min >= 0 && (sum + tolerance * 3) >= max
    end
    
    # Decomposes the alpha channel value given the resulting color, the mask color 
    # and a background color, all of which should be opaque.
    #
    # Make sure to call {#alpha_decomposable?} first to see if the alpha channel
    # value can successfully decomposed with a given tolerance, otherwise the return 
    # value of this method is undefined.
    #
    # @param [Integer] color The color that was the result of compositing.
    # @param [Integer] mask The opauqe variant of the color that was being composed
    # @param [Integer] bg The background color on which the color was composed.
    # @return [Integer] The best fitting alpha channel, a value between 0 and 255.
    # @see #alpha_decomposable?
    def decompose_alpha(color, mask, bg)
      components = decompose_alpha_components(color, mask, bg)
      (components.inject(0) { |a,b| a + b } / 3.0).round
    end
    
    # Decomposes an alpha channel for either the r, g or b color channel.
    # @param [:r, :g, :b] The channel to decompose the alpha channel from.
    # @param [Integer] color The color that was the result of compositing.
    # @param [Integer] mask The opauqe variant of the color that was being composed
    # @param [Integer] bg The background color on which the color was composed.
    # @param [Integer] The decomposed alpha value for the channel.
    def decompose_alpha_component(channel, color, mask, bg)
      ((send(channel, bg) - send(channel, color)).to_f / 
          (send(channel, bg) - send(channel, mask)).to_f * MAX).round
    end
    
    # Decomposes the alpha channels for the r, g and b color channel.
    # @param [Integer] color The color that was the result of compositing.
    # @param [Integer] mask The opauqe variant of the color that was being composed
    # @param [Integer] bg The background color on which the color was composed.    
    # @return [Array<Integer>] The decomposed alpha values for the r, g and b channels.
    def decompose_alpha_components(color, mask, bg)
      [
        decompose_alpha_component(:r, color, mask, bg),
        decompose_alpha_component(:g, color, mask, bg),
        decompose_alpha_component(:b, color, mask, bg)
      ]
    end

    ####################################################################
    # CONVERSIONS
    ####################################################################

    # Returns a string representing this color using hex notation (i.e. #rrggbbaa).
    #
    # @param [Integer] value The color to convert.
    # @return [String] The color in hex notation, starting with a pound sign.
    def to_hex(color, include_alpha = true)
      include_alpha ? ('#%08x' % color) : ('#%06x' % [color >> 8])
    end

    # Returns an array with the separate RGBA values for this color.
    #
    # @param [Integer] color The color to convert.
    # @return [Array<Integer>] An array with 4 Integer elements.
    def to_truecolor_alpha_bytes(color)
      [r(color), g(color), b(color), a(color)]
    end

    # Returns an array with the separate RGB values for this color.
    # The alpha channel will be discarded.
    #
    # @param [Integer] color The color to convert.
    # @return [Array<Integer>] An array with 3 Integer elements.
    def to_truecolor_bytes(color)
      [r(color), g(color), b(color)]
    end

    # Returns an array with the grayscale teint value for this color.
    #
    # This method expects the r,g and b value to be equal, and the alpha 
    # channel will be discarded.
    #
    # @param [Integer] color The grayscale color to convert.
    # @return [Array<Integer>] An array with 1 Integer element.
    def to_grayscale_bytes(color)
      [b(color)] # assumption r == g == b
    end

    # Returns an array with the grayscale teint and alpha channel values
    # for this color.
    #
    # This method expects the r,g and b value to be equal.
    #
    # @param [Integer] color The grayscale color to convert.
    # @return [Array<Integer>] An array with 2 Integer elements.
    def to_grayscale_alpha_bytes(color)
      [b(color), a(color)] # assumption r == g == b
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
    # STATIC UTILITY METHODS
    ####################################################################

    # Returns the number of sample values per pixel.
    # @param [Integer] color_mode The color mode being used.
    # @return [Integer] The number of sample values per pixel.
    def samples_per_pixel(color_mode)
      case color_mode
        when ChunkyPNG::COLOR_INDEXED;         1
        when ChunkyPNG::COLOR_TRUECOLOR;       3
        when ChunkyPNG::COLOR_TRUECOLOR_ALPHA; 4
        when ChunkyPNG::COLOR_GRAYSCALE;       1
        when ChunkyPNG::COLOR_GRAYSCALE_ALPHA; 2
        else raise ChunkyPNG::NotSupported, "Don't know the numer of samples for this colormode: #{color_mode}!"
      end
    end

    # Returns the size in bytes of a pixel when it is stored using a given color mode.
    # @param [Integer] color_mode The color mode in which the pixels are stored.
    # @return [Integer] The number of bytes used per pixel in a datastream.
    def pixel_bytesize(color_mode, depth = 8)
      return 1 if depth < 8
      (pixel_bitsize(color_mode, depth) + 7) >> 3
    end
    
    # Returns the size in bits of a pixel when it is stored using a given color mode.
    # @param [Integer] color_mode The color mode in which the pixels are stored.
    # @param [Integer] depth The color depth of the pixels.
    # @return [Integer] The number of bytes used per pixel in a datastream.
    def pixel_bitsize(color_mode, depth = 8)
      samples_per_pixel(color_mode) * depth
    end
    
    # Returns the number of bytes used per scanline.
    # @param [Integer] color_mode The color mode in which the pixels are stored.
    # @param [Integer] depth The color depth of the pixels.
    # @param [Integer] width The number of pixels per scanline.
    # @return [Integer] The number of bytes used per scanline in a datastream.
    def scanline_bytesize(color_mode, depth, width)
      ((pixel_bitsize(color_mode, depth) * width) + 7) >> 3
    end
    
    # Returns the number of bytes used for an image pass
    # @param [Integer] color_mode The color mode in which the pixels are stored.
    # @param [Integer] depth The color depth of the pixels.
    # @param [Integer] width The width of the image pass.
    # @param [Integer] width The height of the image pass.
    # @return [Integer] The number of bytes used per scanline in a datastream.
    def pass_bytesize(color_mode, depth, width, height)
      return 0 if width == 0 || height == 0
      (scanline_bytesize(color_mode, depth, width) + 1) * height
    end
  end
end
