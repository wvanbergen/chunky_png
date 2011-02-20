module ChunkyPNG
  
  def self.Point(*args)
    ChunkyPNG::Point.single(*args)
  end
  
  # Helper class to deal with points on a canvas
  class Point

    class << self
      
      def single(*args)
        case args.length
          when 2; new(*args)
          when 1; case source = args.first
              when ChunkyPNG::Point; source
              when Array; new(source[0], source[1])
              when Hash; new((source[:x] || source['x']), (source[:y] || source['y']))
              when /^[\(\[\{]?(\d+)\s*[,x]?\s*(\d+)[\)\]\}]?$/; new($1.to_i, $2.to_i)
              else raise ChunkyPNG::ExpectationFailed, "Don't know how to construct a point from #{source.inspect}!"
            end
          else raise ChunkyPNG::ExpectationFailed, "Don't know how to construct a point from #{args.inspect}!"
        end
      end
    
      def multiple_from_array(source)
        return [] if source.empty?
        if source.first.kind_of?(Numeric) || source.first =~ /^\d+$/
          raise ChunkyPNG::ExpectationFailed, "The points array is expected to have an even number of items!" if source.length % 2 != 0

          points = []
          source.each_slice(2) { |x, y| points << new(x, y) }
          return points
        else
          source.map { |p| single(p) }
        end
      end
      
      def multiple_from_string(source_str)
        multiple_from_array(source_str.scan(/[\(\[\{]?(\d+)\s*[,x]?\s*(\d+)[\)\]\}]?/))
      end
    
      def multiple(*source)
        if source.length == 1 && source.first.respond_to?(:scan)
          multiple_from_string(source.first) # e.g. ['1,1 2,2 3,3']
        else
          multiple_from_array(source) # e.g. [[1,1], [2,2], [3,3]] or [1,1,2,2,3,3]
        end
      end
    end
    
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
