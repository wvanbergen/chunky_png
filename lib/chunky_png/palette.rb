module ChunkyPNG
  
  ###########################################
  # PALETTE CLASS
  ###########################################
  
  class Palette
    
    attr_accessor :colors
    
    def initialize
      @colors = {}
      @colors.default = 0
    end
    
    def add_color(color, amount = 1)
      @colors[color] ||= 0
      @colors[color]  += amount
    end
    
    alias :<< :add_color
    
    def reset!
      colors.clear
    end
  end
  
  ###########################################
  # COLOR CLASS
  ###########################################
  
  class Color
    
    attr_accessor :r, :g, :b

    def initialize(r, g, b)
      @r, @g, @b = r, g, b
    end

    ### CONSTRUCTORS ###########################################

    def self.rgb(r, g, b)
      new(r, g, b)
    end

    ### COLOR CONSTANTS ###########################################

    BLACK = rgb(  0,   0,   0)
    WHITE = rgb(255, 255, 255)

    ### CONVERSION ###########################################

    def to_rgb_array
      [r, g, b]
    end

    def to_rgb
      to_rgb_array.pack('CCC')
    end

    def inspect
      '#%02x%02x%02x' % [r, g, b]
    end
    
    ### EQUALITY ###########################################
    
    def ==(other)
      other.kind_of?(self.class) && to_rgb_array == other.to_rgb_array
    end
  end
end
