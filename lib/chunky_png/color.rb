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

    # All the prefined color names for HTML
    PREDEFINED_COLORS = {
      :aliceblue => 0xf0f8ffff,
      :antiquewhite => 0xfaebd7ff,
      :aqua => 0x00ffffff,
      :aquamarine => 0x7fffd4ff,
      :azure => 0xf0ffffff,
      :beige => 0xf5f5dcff,
      :bisque => 0xffe4c4ff,
      :black => 0x000000ff,
      :blanchedalmond => 0xffebcdff,
      :blue => 0x0000ffff,
      :blueviolet => 0x8a2be2ff,
      :brown => 0xa52a2aff,
      :burlywood => 0xdeb887ff,
      :cadetblue => 0x5f9ea0ff,
      :chartreuse => 0x7fff00ff,
      :chocolate => 0xd2691eff,
      :coral => 0xff7f50ff,
      :cornflowerblue => 0x6495edff,
      :cornsilk => 0xfff8dcff,
      :crimson => 0xdc143cff,
      :cyan => 0x00ffffff,
      :darkblue => 0x00008bff,
      :darkcyan => 0x008b8bff,
      :darkgoldenrod => 0xb8860bff,
      :darkgray => 0xa9a9a9ff,
      :darkgrey => 0xa9a9a9ff,
      :darkgreen => 0x006400ff,
      :darkkhaki => 0xbdb76bff,
      :darkmagenta => 0x8b008bff,
      :darkolivegreen => 0x556b2fff,
      :darkorange => 0xff8c00ff,
      :darkorchid => 0x9932ccff,
      :darkred => 0x8b0000ff,
      :darksalmon => 0xe9967aff,
      :darkseagreen => 0x8fbc8fff,
      :darkslateblue => 0x483d8bff,
      :darkslategray => 0x2f4f4fff,
      :darkslategrey => 0x2f4f4fff,
      :darkturquoise => 0x00ced1ff,
      :darkviolet => 0x9400d3ff,
      :deeppink => 0xff1493ff,
      :deepskyblue => 0x00bfffff,
      :dimgray => 0x696969ff,
      :dimgrey => 0x696969ff,
      :dodgerblue => 0x1e90ffff,
      :firebrick => 0xb22222ff,
      :floralwhite => 0xfffaf0ff,
      :forestgreen => 0x228b22ff,
      :fuchsia => 0xff00ffff,
      :gainsboro => 0xdcdcdcff,
      :ghostwhite => 0xf8f8ffff,
      :gold => 0xffd700ff,
      :goldenrod => 0xdaa520ff,
      :gray => 0x808080ff,
      :grey => 0x808080ff,
      :green => 0x008000ff,
      :greenyellow => 0xadff2fff,
      :honeydew => 0xf0fff0ff,
      :hotpink => 0xff69b4ff,
      :indianred => 0xcd5c5cff,
      :indigo => 0x4b0082ff,
      :ivory => 0xfffff0ff,
      :khaki => 0xf0e68cff,
      :lavender => 0xe6e6faff,
      :lavenderblush => 0xfff0f5ff,
      :lawngreen => 0x7cfc00ff,
      :lemonchiffon => 0xfffacdff,
      :lightblue => 0xadd8e6ff,
      :lightcoral => 0xf08080ff,
      :lightcyan => 0xe0ffffff,
      :lightgoldenrodyellow => 0xfafad2ff,
      :lightgray => 0xd3d3d3ff,
      :lightgrey => 0xd3d3d3ff,
      :lightgreen => 0x90ee90ff,
      :lightpink => 0xffb6c1ff,
      :lightsalmon => 0xffa07aff,
      :lightseagreen => 0x20b2aaff,
      :lightskyblue => 0x87cefaff,
      :lightslategray => 0x778899ff,
      :lightslategrey => 0x778899ff,
      :lightsteelblue => 0xb0c4deff,
      :lightyellow => 0xffffe0ff,
      :lime => 0x00ff00ff,
      :limegreen => 0x32cd32ff,
      :linen => 0xfaf0e6ff,
      :magenta => 0xff00ffff,
      :maroon => 0x800000ff,
      :mediumaquamarine => 0x66cdaaff,
      :mediumblue => 0x0000cdff,
      :mediumorchid => 0xba55d3ff,
      :mediumpurple => 0x9370d8ff,
      :mediumseagreen => 0x3cb371ff,
      :mediumslateblue => 0x7b68eeff,
      :mediumspringgreen => 0x00fa9aff,
      :mediumturquoise => 0x48d1ccff,
      :mediumvioletred => 0xc71585ff,
      :midnightblue => 0x191970ff,
      :mintcream => 0xf5fffaff,
      :mistyrose => 0xffe4e1ff,
      :moccasin => 0xffe4b5ff,
      :navajowhite => 0xffdeadff,
      :navy => 0x000080ff,
      :oldlace => 0xfdf5e6ff,
      :olive => 0x808000ff,
      :olivedrab => 0x6b8e23ff,
      :orange => 0xffa500ff,
      :orangered => 0xff4500ff,
      :orchid => 0xda70d6ff,
      :palegoldenrod => 0xeee8aaff,
      :palegreen => 0x98fb98ff,
      :paleturquoise => 0xafeeeeff,
      :palevioletred => 0xd87093ff,
      :papayawhip => 0xffefd5ff,
      :peachpuff => 0xffdab9ff,
      :peru => 0xcd853fff,
      :pink => 0xffc0cbff,
      :plum => 0xdda0ddff,
      :powderblue => 0xb0e0e6ff,
      :purple => 0x800080ff,
      :red => 0xff0000ff,
      :rosybrown => 0xbc8f8fff,
      :royalblue => 0x4169e1ff,
      :saddlebrown => 0x8b4513ff,
      :salmon => 0xfa8072ff,
      :sandybrown => 0xf4a460ff,
      :seagreen => 0x2e8b57ff,
      :seashell => 0xfff5eeff,
      :sienna => 0xa0522dff,
      :silver => 0xc0c0c0ff,
      :skyblue => 0x87ceebff,
      :slateblue => 0x6a5acdff,
      :slategray => 0x708090ff,
      :slategrey => 0x708090ff,
      :snow => 0xfffafaff,
      :springgreen => 0x00ff7fff,
      :steelblue => 0x4682b4ff,
      :tan => 0xd2b48cff,
      :teal => 0x008080ff,
      :thistle => 0xd8bfd8ff,
      :tomato => 0xff6347ff,
      :turquoise => 0x40e0d0ff,
      :violet => 0xee82eeff,
      :wheat => 0xf5deb3ff,
      :white => 0xffffffff,
      :whitesmoke => 0xf5f5f5ff,
      :yellow => 0xffff00ff,
      :yellowgreen => 0x9acd32ff,
      :transparent => 0x00000000
    }
    
    def html_color(color_name)
      PREDEFINED_COLORS[color_name.to_s.gsub(/[^a-z]+/i, '').downcase.to_sym]
    end
    
    alias_method :[], :html_color

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
