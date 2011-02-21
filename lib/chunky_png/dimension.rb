module ChunkyPNG
  
  # Creates a {ChunkyPNG::Dimension} instance using arguments that can be interpreted 
  # as width and height.
  # 
  # @returns [ChunkyPNG::Dimension] The parsed Dimension
  def self.Dimension(*args)
    return args.first if args.length == 1 && args.first.kind_of?(ChunkyPNG::Dimension)
    ChunkyPNG::Dimension.new(*ChunkyPNG::Point(*args))
  end
  
  # Class that represents the dimension of something, e.g. a {ChunkyPNG::Canvas}.
  #
  # This class contains some methods to simplify performing dimension related checks.
  class Dimension

    # @return [Integer] The width-compontent of this dimension.
    attr_accessor :width
    
    # @return [Integer] The height-compontent of this dimension.
    attr_accessor :height
    
    # Initializes a new dimension instance.
    # @param [Integer] width The width-compontent of the new dimension.
    # @param [Integer] height The height-compontent of the new dimension.
    def initialize(width, height)
      @width, @height = width, height
    end
    
    # Returns the area of this dimension.
    # @return [Integer] The area in number of pixels.
    def area
      width * height
    end
    
    # Checks whether a point is within bounds of this dimension.
    # @param [ChunkyPNG::Point, ...] A point-like to bounds-check.
    # @return [true, false] True iff the the x and y coordinate fall in this dimension.
    def include?(*point_like)
      point = ChunkyPNG::Point(*point_like)
      point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    end
    
    # Checks whether 2 dimensions are identical.
    # @param [ChunkyPNG::Dimension] The dimension to compare with.
    # @return [true, false] <tt>true</tt> iff width and height match.
    def eql?(other)
      other.width == width && other.height == height
    end
    
    alias_method :==, :eql?
    
    # Compares the size of 2 dimensions.
    # @param [ChunkyPNG::Dimension] The dimension to compare with.
    # @return [-1, 0, 1] -1 if the other dimension has a larger area, 1 of this
    #   dimension is larger, 0 if both are identical in size.
    def <=>(other)
      other.area <=> area
    end
    
    # Casts this dimension into an array.
    # @return [Array<Integer>] <tt>[width, height]</tt> for this dimension.
    def to_a
      [width, height]
    end
    
    alias_method :to_ary, :to_a
  end
end