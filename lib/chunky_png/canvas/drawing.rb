module ChunkyPNG
  class Canvas
    
    # Module that adds some primitive drawing methods to {ChunkyPNG::Canvas}.
    #
    # All of these methods change the current canvas instance and do not create a new one,
    # even though the method names do not end with a bang.
    #
    # @note Drawing operations will not fail when something is drawn outside of the bounds
    #       of the canvas; these pixels will simply be ignored.
    # @see ChunkyPNG::Canvas
    module Drawing
      
      # Composes a pixel on the canvas by alpha blending a color with its background color.
      # @overload compose_pixel(x, y, color)
      #   @param [Integer] x The x-coordinate of the pixel to blend.
      #   @param [Integer] y The y-coordinate of the pixel to blend.
      #   @param [Integer] color The foreground color to blend with
      # @overload compose_pixel(point, color)
      #   @param [ChunkyPNG::Point, ...] point The point on the canvas to blend.
      #   @param [Integer] color The foreground color to blend with
      def compose_pixel(*args)
        point = args.length == 2 ? ChunkyPNG::Point(args.first) : ChunkyPNG::Point(args[0], args[1])
        return unless include?(point)
        color = ChunkyPNG::Color(args.last)
        set_pixel(point.x, point.y, ChunkyPNG::Color.compose(color, get_pixel(point.x, point.y)))
      end
      
      # Draws an anti-aliased line using Xiaolin Wu's algorithm.
      #
      # @param [Integer] x0 The x-coordinate of the first control point.
      # @param [Integer] y0 The y-coordinate of the first control point.
      # @param [Integer] x1 The x-coordinate of the second control point.
      # @param [Integer] y1 The y-coordinate of the second control point.
      # @param [Integer] stroke_color The color to use for this line.
      # @param [true, false] inclusive Whether to draw the last pixel. 
      #    Set to false when drawing multiplelines in a path.
      # @return [ChunkyPNG::Canvas] Itself, with the line drawn.
      def line_xiaolin_wu(x0, y0, x1, y1, stroke_color, inclusive = true)
        
        stroke_color = ChunkyPNG::Color(stroke_color)
        
        dx = x1 - x0
        sx = dx < 0 ? -1 : 1
        dx *= sx
        dy = y1 - y0
        sy = dy < 0 ? -1 : 1
        dy *= sy
        
        if dy == 0 # vertical line
          x0.step(inclusive ? x1 : x1 - sx, sx) do |x|
            compose_pixel(x, y0, stroke_color)
          end
          
        elsif dx == 0 # horizontal line
          y0.step(inclusive ? y1 : y1 - sy, sy) do |y|
            compose_pixel(x0, y, stroke_color)
          end
          
        elsif dx == dy # diagonal
          x0.step(inclusive ? x1 : x1 - sx, sx) do |x|
            compose_pixel(x, y0, stroke_color)
            y0 += sy
          end
          
        elsif dy > dx  # vertical displacement
          compose_pixel(x0, y0, stroke_color)
          e_acc = 0
          e = ((dx << 16) / dy.to_f).round
          (dy - 1).downto(0) do |i|
            e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xffff
            x0 += sx if (e_acc <= e_acc_temp)
            w = 0xff - (e_acc >> 8)
            compose_pixel(x0, y0, ChunkyPNG::Color.fade(stroke_color, w))
            compose_pixel(x0 + sx, y0 + sy, ChunkyPNG::Color.fade(stroke_color, 0xff - w)) if inclusive || i > 0
            y0 += sy
          end
          compose_pixel(x1, y1, stroke_color) if inclusive
          
        else # horizontal displacement
          compose_pixel(x0, y0, stroke_color)
          e_acc = 0
          e = ((dy << 16) / dx.to_f).round
          (dx - 1).downto(0) do |i|
            e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xffff
            y0 += sy if (e_acc <= e_acc_temp)
            w = 0xff - (e_acc >> 8)
            compose_pixel(x0, y0, ChunkyPNG::Color.fade(stroke_color, w))
            compose_pixel(x0 + sx, y0 + sy, ChunkyPNG::Color.fade(stroke_color, 0xff - w)) if inclusive || i > 0
            x0 += sx
          end
          compose_pixel(x1, y1, stroke_color) if inclusive
        end
        
        return self
      end
      
      alias_method :line, :line_xiaolin_wu
      
      
      # Draws a polygon on the canvas using the stroke_color, filled using the fill_color if any.
      #
      # @param [Array, String] The control point vector. Accepts everything {ChunkyPNG.Vector} accepts.
      # @param [Integer] stroke_color The stroke color to use for this polygon.
      # @param [Integer] fill_color The fill color to use for this polygon.
      # @return [ChunkyPNG::Canvas] Itself, with the polygon drawn.
      def polygon(path, stroke_color = ChunkyPNG::Color::BLACK, fill_color = ChunkyPNG::Color::TRANSPARENT)
        
        vector = ChunkyPNG::Vector(*path)
        raise ArgumentError, "A polygon requires at least 3 points" if path.length < 3

        stroke_color = ChunkyPNG::Color(stroke_color)
        fill_color   = ChunkyPNG::Color(fill_color)

        # Fill
        unless fill_color == ChunkyPNG::Color::TRANSPARENT
          vector.y_range.each do |y|
            intersections = []
            vector.edges.each do |p1, p2|
              if (p1.y < y && p2.y >= y) || (p2.y < y && p1.y >= y)
                intersections << (p1.x + (y - p1.y).to_f / (p2.y - p1.y) * (p2.x - p1.x)).round
              end
            end

            intersections.sort!
            0.step(intersections.length - 1, 2) do |i|
              intersections[i].upto(intersections[i + 1]) do |x|
                compose_pixel(x, y, fill_color)
              end
            end
          end
        end
        
        # Stroke
        vector.each_edge do |(from_x, from_y), (to_x, to_y)|
          line(from_x, from_y, to_x, to_y, stroke_color, false)
        end

        return self
      end
      
      # Draws a rectangle on the canvas, using two control points.
      #
      # @param [Integer] x0 The x-coordinate of the first control point.
      # @param [Integer] y0 The y-coordinate of the first control point.
      # @param [Integer] x1 The x-coordinate of the second control point.
      # @param [Integer] y1 The y-coordinate of the second control point.
      # @param [Integer] stroke_color The line color to use for this rectangle.
      # @param [Integer] fill_color The fill color to use for this rectangle.
      # @return [ChunkyPNG::Canvas] Itself, with the rectangle drawn.
      def rect(x0, y0, x1, y1, stroke_color = ChunkyPNG::Color::BLACK, fill_color = ChunkyPNG::Color::TRANSPARENT)
      
        stroke_color = ChunkyPNG::Color(stroke_color)
        fill_color   = ChunkyPNG::Color(fill_color)
      
        # Fill
        unless fill_color == ChunkyPNG::Color::TRANSPARENT
          [x0, x1].min.upto([x0, x1].max) do |x|
            [y0, y1].min.upto([y0, y1].max) do |y|
              compose_pixel(x, y, fill_color)
            end
          end
        end
        
        # Stroke
        line(x0, y0, x0, y1, stroke_color, false)
        line(x0, y1, x1, y1, stroke_color, false)
        line(x1, y1, x1, y0, stroke_color, false)
        line(x1, y0, x0, y0, stroke_color, false)
        
        return self
      end
      
      # Draws a circle on the canvas.
      #
      # @param [Integer] x0 The x-coordinate of the center of the circle.
      # @param [Integer] y0 The y-coordinate of the center of the circle.
      # @param [Integer] radius The radius of the circle from the center point.
      # @param [Integer] stroke_color The color to use for the line.
      # @param [Integer] fill_color The color to use that fills the circle.
      # @return [ChunkyPNG::Canvas] Itself, with the circle drawn.
      def circle(x0, y0, radius, stroke_color = ChunkyPNG::Color::BLACK, fill_color = ChunkyPNG::Color::TRANSPARENT)

        stroke_color = ChunkyPNG::Color(stroke_color)
        fill_color   = ChunkyPNG::Color(fill_color)

        f = 1 - radius
        ddF_x = 1
        ddF_y = -2 * radius
        x = 0
        y = radius

        compose_pixel(x0, y0 + radius, stroke_color)
        compose_pixel(x0, y0 - radius, stroke_color)
        compose_pixel(x0 + radius, y0, stroke_color)
        compose_pixel(x0 - radius, y0, stroke_color)

        lines = [radius - 1] unless fill_color == ChunkyPNG::Color::TRANSPARENT

        while x < y

          if f >= 0
            y -= 1
            ddF_y += 2
            f += ddF_y
          end

          x += 1
          ddF_x += 2
          f += ddF_x

          unless fill_color == ChunkyPNG::Color::TRANSPARENT
            lines[y] = lines[y] ? [lines[y], x - 1].min : x - 1
            lines[x] = lines[x] ? [lines[x], y - 1].min : y - 1
          end

          compose_pixel(x0 + x, y0 + y, stroke_color)
          compose_pixel(x0 - x, y0 + y, stroke_color)
          compose_pixel(x0 + x, y0 - y, stroke_color)
          compose_pixel(x0 - x, y0 - y, stroke_color)

          unless x == y
            compose_pixel(x0 + y, y0 + x, stroke_color)
            compose_pixel(x0 - y, y0 + x, stroke_color)
            compose_pixel(x0 + y, y0 - x, stroke_color)
            compose_pixel(x0 - y, y0 - x, stroke_color)
          end
        end

        unless fill_color == ChunkyPNG::Color::TRANSPARENT
          lines.each_with_index do |length, y|
            line(x0 - length, y0 - y, x0 + length, y0 - y, fill_color) if length > 0
            line(x0 - length, y0 + y, x0 + length, y0 + y, fill_color) if length > 0 && y > 0
          end
        end

        return self
      end
    end
  end
end
