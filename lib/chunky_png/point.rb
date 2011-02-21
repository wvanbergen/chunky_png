module ChunkyPNG
  
  def self.Point(*args)
    case args.length
      when 2; ChunkyPNG::Point.new(*args)
      when 1; case source = args.first
          when ChunkyPNG::Point; source
          when ChunkyPNG::Dimension; ChunkyPNG::Point.new(source.width, source.height)
          when Array; ChunkyPNG::Point.new(source[0], source[1])
          when Hash; ChunkyPNG::Point.new(source[:x] || source['x'], source[:y] || source['y'])
          when /^[\(\[\{]?(\d+)\s*[,]?\s*(\d+)[\)\]\}]?$/; ChunkyPNG::Point.new($1.to_i, $2.to_i)
          else 
            if source.respond_to?(:x) && source.respond_to?(:y)
              ChunkyPNG::Point.new(source.x, source.y)
            else
              raise ChunkyPNG::ExpectationFailed, "Don't know how to construct a point from #{source.inspect}!"
            end
        end
      else raise ChunkyPNG::ExpectationFailed, "Don't know how to construct a point from #{args.inspect}!"
    end
  end
  
  # Helper class to deal with points on a canvas
  class Point

    # @return [Integer] The x-coordinate of the point.
    attr_accessor :x

    # @return [Integer] The y-coordinate of the point.
    attr_accessor :y
    
    def initialize(x, y)
      @x, @y = x.to_i, y.to_i
    end
    
    # Checks whether 2 points are identical.
    # @return [true, false] <tt>true</tt> iff the x and y coordinates match
    def eql?(other)
      other.x == x && other.y == y
    end
    
    alias_method :==, :eql?
    
    def <=>(other)
      ((y <=> other.y) == 0) ? x <=> other.x : y <=> other.y
    end
    
    def to_a
      [x, y]
    end
    
    alias_method :to_ary, :to_a
    
    def within_bounds?(*args)
      ChunkyPNG::Dimension(*args).include?(self)
    end
  end
end
