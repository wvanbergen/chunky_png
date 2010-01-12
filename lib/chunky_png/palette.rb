module ChunkyPNG
  
  ###########################################
  # PALETTE CLASS
  ###########################################
  
  class Palette < SortedSet
    
    def initialize(enum)
      super(enum)
      @decoding_map = enum if enum.kind_of?(Array)
    end
    
    def self.from_chunks(palette_chunk, transparency_chunk = nil)
      return nil if palette_chunk.nil?
      
      decoding_map = []
      index = 0
      
      palatte_bytes = palette_chunk.content.unpack('C*')
      if transparency_chunk
        alpha_channel = transparency_chunk.content.unpack('C*')
      else
        alpha_channel = Array.new(palatte_bytes.size / 3, 255)
      end
      
      index = 0
      palatte_bytes.each_slice(3) do |bytes|
        bytes << alpha_channel[index]
        decoding_map << ChunkyPNG::Pixel.rgba(*bytes)
        index += 1
      end
      
      self.new(decoding_map)
    end
    
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

    def can_decode?
      !@decoding_map.nil?
    end
    
    def can_encode?
      !@encoding_map.nil?
    end
    
    def [](index)
      @decoding_map[index]
    end
    
    def index(color)
      @encoding_map[color]
    end
    
    def to_trns_chunk
      ChunkyPNG::Chunk::Transparency.new('tRNS', map(&:a).pack('C*'))
    end
    
    def to_plte_chunk
      @encoding_map = {}
      colors     = []
      
      each_with_index do |color, index|
        @encoding_map[color] = index
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
