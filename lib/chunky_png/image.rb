module ChunkyPNG
  class Image

    attr_reader :pixel_matrix

    def initialize(width, height, background_color = ChunkyPNG::Color::TRANSPARENT)
      @pixel_matrix = ChunkyPNG::PixelMatrix.new(width, height, background_color)
    end

    def self.from_pixel_matrix(matrix)
      self.new(matrix.width, matrix.height, matrix.pixels)
    end

    def width
      pixel_matrix.width
    end

    def height
      pixel_matrix.height
    end

    def [](x, y)
      pixel_matrix[x,y]
    end

    def []=(x, y, pixel)
      pixel_matrix[x,y] = pixel
    end

    def pixels
      pixel_matrix.pixels
    end

    def write(io, constraints = {})
      datastream = pixel_matrix.to_datastream(constraints)
      datastream.write(io)
    end

    def save(filename, constraints = {})
      File.open(filename, 'w') { |io| write(io, constraints) }
    end
  end
end