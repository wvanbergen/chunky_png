module ChunkyPNG
  
  # Helper class to deal with points on a canvas
  class Point

    class << self
      
      def single(source)
        case source
          when ChunkyPNG::Point; source
          when Array; new(source[0], source[1])
          when Hash; new((source[:x] || source['x']), (source[:y] || source['y']))
          when /^[\(\[\{]?(\d+)\s*,?\s*(\d+)[\)\]\}]?$/; new($1.to_i, $2.to_i)
          else raise ChunkyPNG::ExpectationFailed, "Don't know how to construct a point from #{source.inspect}!"
        end
      end
    
      alias_method :[], :single
    
      def multiple_from_array(source)
        return [] if source.empty?
        if source.first.kind_of?(Numeric) || source.first =~ /^\d+$/
          raise ChunkyPNG::ExpectationFailed, "The points array is expected to have an even number of items!" if source.length % 2 != 0
          [].tap { |points| source.each_slice(2) { |x, y| points << new(x, y) } }
        else
          source.map { |p| single(p) }
        end
      end
      
      def multiple_from_string(source)
        multiple_from_array(source.to_s.scan(/[\(\[\{]?(\d+)\s*,?\s*(\d+)[\)\]\}]?/))
      end
    
      def multiple(source)
        case source
          when Array;  multiple_from_array(source)
          when String; multiple_from_string(source)
          else raise ChunkyPNG::ExpectationFailed, "Cannot parse multiple points from #{source.inspect}!"
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
    
    def in_bounds?(canvas)
      canvas.include_xy?(x, y)
    end
    
    # Checks whether 2 points are identical.
    # @return [true, false] <tt>true</tt> iff the x and y coordinates match
    def eql?(other)
      other.x == x && other.y == y
    end
    
    alias :== :eql?
    
    def <=>(other)
      ((y <=> other.y) == 0) ? x <=> other.x : y <=> other.y
    end
  end
end
