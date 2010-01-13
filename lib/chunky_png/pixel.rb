module ChunkyPNG

  class Pixel
        
    attr_reader :value
    
    def initialize(value)
      @value = value
    end

    def self.rgb(r, g, b)
      rgba(r, g, b, 255)
    end
    
    def self.rgba(r, g, b, a)
      new(r << 24 | g << 16 | b << 8 | a)
    end
    
    def self.grayscale(teint, a = 255)
      rgba(teint, teint, teint, a)
    end
    
    def self.from_rgb_stream(stream)
      self.rgb(*stream.unpack('C3'))
    end

    def self.from_rgba_stream(stream)
      self.rgba(*stream.unpack('C4'))
    end
    
    def r
      (@value & 0xff000000) >> 24
    end

    def g
      (@value & 0x00ff0000) >> 16
    end

    def b
      (@value & 0x0000ff00) >> 8
    end

    def a
      @value & 0x000000ff
    end
    
    def opaque?
      a == 0x000000ff
    end
    
    def grayscale?
      r == g && r == b
    end
    
    def inspect
      '#%08x' % @value
    end
    
    def hash
      @value.hash
    end
    
    def compose_on(other_pixel)
      if a == 255
        self
      elsif a == 0
        other_pixel
      else
        alpha       = a / 255.0
        alpha_com   = 1.0 - alpha
        other_alpha = other_pixel.a / 255.0

        new_r = (alpha * r + alpha_com * other_alpha * other_pixel.r).round
        new_g = (alpha * g + alpha_com * other_alpha * other_pixel.g).round
        new_b = (alpha * b + alpha_com * other_alpha * other_pixel.b).round
        new_a = ((alpha + alpha_com * other_alpha) * 255).round
        ChunkyPNG::Pixel.rgba(new_r, new_g, new_b, new_a)
      end
    end
    
    def eql?(other)
      other.kind_of?(self.class) && other.value == self.value
    end
    
    alias :== :eql?
    
    def <=>(other)
      other.value <=> self.value
    end
    
    def to_truecolor_alpha_bytes
      [r,g,b,a]
    end

    def to_truecolor_bytes
      [r,g,b]
    end
    
    def index(palette)
      palette.index(self)
    end
    
    def to_indexed_bytes(palette)
      [index(palette)]
    end
    
    def to_grayscale_bytes
      [r] # Assumption: r == g == b
    end

    def to_grayscale_alpha_bytes
      [r, a] # Assumption: r == g == b
    end
    
    BLACK = rgb(  0,   0,   0)
    WHITE = rgb(255, 255, 255)
    
    TRANSPARENT = rgba(0, 0, 0, 0)
    
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
