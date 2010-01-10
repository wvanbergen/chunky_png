module ChunkyPNG
  
  ###########################################
  # PALETTE CLASS
  ###########################################
  
  class Palette < Set
    
    def self.from_pixel_matrix(pixel_matrix)
      from_pixels(pixel_matrix.pixels)
    end
    
    def self.from_pixels(pixels)
      from_colors(pixels.map(&:color))
    end
    
    def self.from_colors(colors)
      palette = self.new
      colors.each { |color| palette << color }
      palette
    end
    
    def indexable?
      size < 256
    end
    
    def index(color)
      @color_map[color]
    end
    
    def to_plte_chunk
      @color_map = {}
      colors     = []
      
      each_with_index do |color, index|
        @color_map[color] = index
        colors += color.to_rgb_array
      end
      
      ChunkyPNG::Chunk::Generic.new('PLTE', colors.pack('C*'))
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

    def index(palette)
      palette.index(self)
    end

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
