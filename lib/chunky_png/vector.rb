module ChunkyPNG

  # Factory method for {ChunkyPNG::Vector} instances.
  #
  # @overload Vector(x0, y0, x1, y1, x2, y2, ...)
  #   Creates a vector by parsing two subsequent values in the argument list 
  #   as x- and y-coordinate of a point.
  #   @return [ChunkyPNG::Vector] The instantiated vector.
  # @overload Vector(string)
  #   Creates a vector by parsing coordinates from the input string.
  #   @return [ChunkyPNG::Vector] The instantiated vector.
  # @overload Vector(pointlike, pointlike, pointlike, ...)
  #   Creates a vector by converting every argument to a point using {ChunkyPNG.Point}.
  #   @return [ChunkyPNG::Vector] The instantiated vector.
  #
  # @raise [ArgumentError] If the given arguments could not be understood as a vector.
  def self.Vector(*args)
    
    return args.first if args.length == 1 && args.first.kind_of?(ChunkyPNG::Vector)
    
    if args.length == 1 && args.first.respond_to?(:scan)
      ChunkyPNG::Vector.new(ChunkyPNG::Vector.multiple_from_string(args.first)) # e.g. ['1,1 2,2 3,3']
    else
      ChunkyPNG::Vector.new(ChunkyPNG::Vector.multiple_from_array(args)) # e.g. [[1,1], [2,2], [3,3]] or [1,1,2,2,3,3]
    end
  end
  
  # Class that represents a vector of points, i.e. a list of {ChunkyPNG::Point} instances.
  class Vector
    
    include Enumerable
    
    attr_reader :points
    
    def initialize(points = [])
      @points = points
    end
    
    def each_edge(close = true)
      raise ChunkyPNG::ExpectationFailed, "Not enough points in this path to draw an edge!" if length < 2
      points.each_cons(2) { |a, b| yield(a, b) }
      yield(points.last, points.first) if close
    end
    
    def edges(close = true)
      Enumerator.new(self, :each_edge, close)
    end
    
    def length
      points.length
    end
    
    def each(&block)
      points.each(&block)
    end
    
    def eql?(other)
      other.points == points
    end
    
    alias_method :==, :eql?
    
    def to_a
      edges
    end
    
    alias_method :to_ary, :to_a

    def x_range
      Range.new(*points.map { |p| p.x }.minmax)
    end
    
    def y_range
      Range.new(*points.map { |p| p.y }.minmax)
    end
    
    def self.multiple_from_array(source)
      return [] if source.empty?
      if source.first.kind_of?(Numeric) || source.first =~ /^\d+$/
        raise ArgumentError, "The points array is expected to have an even number of items!" if source.length % 2 != 0

        points = []
        source.each_slice(2) { |x, y| points << ChunkyPNG::Point.new(x, y) }
        return points
      else
        source.map { |p| ChunkyPNG::Point(p) }
      end
    end
    
    def self.multiple_from_string(source_str)
      multiple_from_array(source_str.scan(/[\(\[\{]?(\d+)\s*[,x]?\s*(\d+)[\)\]\}]?/))
    end
  end
end
