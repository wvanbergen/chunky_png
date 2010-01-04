module ChunkyPNG
  class Color < Struct.new(:r, :g, :b, :a)

    BLACK = self.new(  0,   0,   0, 255)
    WHITE = self.new(255, 255, 255, 255)

    def to_true_color
      [r, g, b].pack('CCC')
    end

    def inspect
      '#%02x%02x%02x' % [r, g, b]
    end

    def self.rgb(r, g, b)
      self.new(r, g, b, 255)
    end

    def self.rgba(r, g, b, a)
      self.new(r, g, b, a)
    end
  end
end
