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
    
    def inspect
      '#%08x' % @value
    end
    
    def eql?(other)
      other.kind_of?(self) && other.value == self.value
    end
    
    def to_rgba_stream
      [r,g,b,a].pack('C4')
    end
    
    def to_rgba_bytes
      [r,g,b,a]
    end
    
    def to_rgb_stream
      [r,g,b].pack('C3')
    end
    
    def to_rgb_bytes
      [r,g,b]
    end
    
    def index(palette)
      [palette.index(self)]
    end
    
    BLACK = rgb(  0,   0,   0)
    WHITE = rgb(255, 255, 255)
    
    TRANSPARENT = rgba(0 , 0, 0, 0)
    
    def self.bytesize(color_mode)
      case color_mode
        when ChunkyPNG::Chunk::Header::COLOR_INDEXED         then 1
        when ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR       then 3
        when ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR_ALPHA then 4
        when ChunkyPNG::Chunk::Header::COLOR_GRAYSCALE       then 1
        when ChunkyPNG::Chunk::Header::COLOR_GRAYSCALE_ALPHA then 2
        else raise "Don't know the bytesize of pixels in this colormode: #{color_mode}!"
      end
    end
  end
end
