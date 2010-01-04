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

    def to_true_color
      [r, g, b].pack('CCC')
    end

    def inspect
      '#%02x%02x%02x' % [r, g, b]
    end

  end
end
