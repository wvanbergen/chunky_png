module ChunkyPNG
  
  ###########################################
  # PALETTE CLASS
  ###########################################
  
  class Palette < SortedSet
    
    def self.from_pixel_matrix(pixel_matrix)
      self.new(pixel_matrix.pixels)
    end
    
    def self.from_pixels(pixels)
      self.new(pixels)
    end
    
    def indexable?
      size < 256
    end
    
    def opaque?
      all? { |pixel| pixel.opaque? }
    end
    
    def index(color)
      @color_map[color]
    end
    
    def to_trns_chunk
      ChunkyPNG::Chunk::Generic.new('tRNS', map(&:a).pack('C*'))
    end
    
    def to_plte_chunk
      @color_map = {}
      colors     = []
      
      each_with_index do |color, index|
        @color_map[color] = index
        colors += color.to_truecolor_bytes
      end
      
      ChunkyPNG::Chunk::Palette.new('PLTE', colors.pack('C*'))
    end
    
    def best_colormode
      if indexable?
        ChunkyPNG::Chunk::Header::COLOR_INDEXED
      elsif opaque?
        ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR
      else
        ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR_ALPHA
      end
    end
  end
end
