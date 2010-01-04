module ChunkyPNG
  class Image
    
    attr_reader :width, :height, :pixelvector
    
    def initialize(width, height)
      @width, @height = width, height
      black_pixel = ChunkyPNG::Color.new(255, 0, 0)
      @pixelvector = Array.new(width * height, black_pixel)
    end
    
    
    def write(io)
      datastream = ChunkyPNG::Datastream.new
      datastream.chunks << ChunkyPNG::Chunk::Header.new(:width => width, :height => height)
      
      pixels = @pixelvector.map(&:to_true_color).join('')
      datastream.chunks << ChunkyPNG::Chunk::PixelData.new(pixels) # FIXME
      datastream.chunks << ChunkyPNG::Chunk::Generic.new('IEND')
      datastream.write(io)
    end
  end
end