module ChunkyPNG
  class Image
    
    attr_reader :width, :height, :pixelvector
    
    def initialize(width, height)
      @width, @height = width, height
      black_pixel = PNG::Color.new(255, 0, 0)
      @pixelvector = Array.new(width * height, black_pixel)
    end
    
    
    def write(io)
      datastream = PNG::Datastream.new
      datastream.chunks << PNG::Chunk::Header.new(:width => width, :height => height)
      
      pixels = @pixelvector.map(&:to_true_color).join('')
      datastream.chunks << PNG::Chunk::PixelData.new(pixels)
      datastream.chunks << PNG::Chunk::Generic.new('IEND')
      datastream.write(io)
    end
  end
end