module ChunkyPNG

  def self.Vector(*args)
    return args.first if args.length == 1 && args.first.kind_of?(ChunkyPNG::Vector)
    ChunkyPNG::Vector.new(ChunkyPNG::Point.multiple(*args))
  end
    
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
  end
end
