module ChunkyPNG

  def self.Path(*args)
    return args.first if args.length == 1 && args.first.kind_of?(ChunkyPNG::Path)
    ChunkyPNG::Path.new(ChunkyPNG::Point.multiple(*args))
  end
    
  class Path
    attr_reader :points
    
    def initialize(points = [])
      @points = points
    end
    
    def each_edge
      raise ChunkyPNG::ExpectationFailed, "Not enough points in this path to draw an edge!" if length < 2
      points.each_cons(2) { |a, b| yield(a, b) }
      yield(points.last, points.first)
    end
    
    def edges
      Enumerable::Enumerator.new(self, :each_edge)
    end
    
    def length
      points.length
    end
    
    def eql?(other)
      other.points == points
    end
    
    alias_method :==, :eql?
  end
end
