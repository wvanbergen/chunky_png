module ChunkyPNG
  
  def self.Dimension(*args)
    return args.first if args.length == 1 && args.first.kind_of?(ChunkyPNG::Dimension)
    ChunkyPNG::Dimension.new(*ChunkyPNG::Point(*args))
  end
  
  class Dimension
    attr_accessor :width, :height
    
    def initialize(width, height)
      @width, @height = width, height
    end
    
    # Returns the size
    def area
      width * height
    end
    
    def include?(*point_like)
      point = ChunkyPNG::Point(*point_like)
      point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    end
    
    # Checks whether 2 dimensions are identical.
    # @return [true, false] <tt>true</tt> iff width and height match.
    def eql?(other)
      other.width == width && other.height == height
    end
    
    alias_method :==, :eql?
    
    def <=>(other)
      other.area <=> area
    end    
    
    def to_a
      [width, height]
    end
    
    alias_method :to_ary, :to_a
  end
end