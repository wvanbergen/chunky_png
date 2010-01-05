module ChunkyPNG
  class Color
    
    attr_accessor :r, :g, :b, :a

    def initialize(r, g, b, a = 255)
      @r, @g, @b, @a = r, g, b, a
    end

    ###########################################
    # CONSTRUCTORS
    ###########################################

    def self.rgb(r, g, b)
      new(r, g, b)
    end

    def self.rgba(r, g, b, a)
      new(r, g, b, a)
    end

    ###########################################
    # COLOR CONSTANTS
    ###########################################
    
    BLACK = rgba(  0,   0,   0, 255)
    WHITE = rgba(255, 255, 255, 255)

    ###########################################
    # CONVERSION
    ###########################################

    def to_rgb_array
      [r, g, b]
    end
    
    def to_rgba_array
      [r, g, b, a]
    end    
    
    def to_rgb
      to_rgb_array.pack('CCC')
    end

    def inspect
      '#%02x%02x%02x' % [r, g, b]
    end
    
    def ==(other)
      other.kind_of?(self.class) && to_rgba_array == other.to_rgba_array
    end
  end
end
