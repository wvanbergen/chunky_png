module ChunkyPNG
  class Canvas
    
    module Drawing
      
      # Sets a point on the canvas by composing a pixel with its background color.
      def point(x_or_point, y_or_color, color = nil)
        point = color.nil? ? ChunkyPNG::Point(x_or_point) : ChunkyPNG::Point(x_or_point, y_or_color)
        return unless include?(point)
        set_pixel(point.x, point.y, ChunkyPNG::Color.compose(color || y_or_color, get_pixel(point.x, point.y)))
      end
      
      # Draws an anti-aliased line using Xiaolin Wu's algorithm.
      #
      def line_xiaolin_wu(x0, y0, x1, y1, color)
        y0, y1, x0, x1 = y1, y0, x1, x0 if y0 > y1
        dx = x1 - x0
        sx = dx < 0 ? -1 : 1
        dx *= sx
        dy = y1 - y0
        
        if dy == 0 # vertical line
          Range.new(*[x0,x1].sort).each do |x|
            point(x, y0, color)
          end
        elsif dx == 0 # horizontal line
          (y0..y1).each do |y|
            point(x0, y, color)
          end
        elsif dx == dy # diagonal
          x0.step(x1, sx) do |x|
            point(x, y0, color)
            y0 += 1
          end
          
        elsif dy > dx  # vertical displacement
          point(x0, y0, color)
          e_acc = 0          
          e = ((dx << 16) / dy.to_f).round
          (y0...y1-1).each do |i|
            e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xffff
            x0 = x0 + sx if (e_acc <= e_acc_temp)
            w = 0xff - (e_acc >> 8)
            point(x0, y0, ChunkyPNG::Color.fade(color, w)) if include_xy?(x0, y0)
            y0 = y0 + 1
            point(x0 + sx, y0, ChunkyPNG::Color.fade(color, 0xff - w)) if include_xy?(x0 + sx, y0)
          end
          point(x1, y1, color)
          
        else # horizontal displacement
          point(x0, y0, color)
          e_acc = 0
          e = (dy << 16) / dx
          (dx - 1).downto(0) do |i|
            e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xffff
            y0 += 1 if (e_acc <= e_acc_temp)
            w = 0xff - (e_acc >> 8)
            point(x0, y0, ChunkyPNG::Color.fade(color, w)) if include_xy?(x0, y0)
            x0 += sx
            point(x0, y0 + 1, ChunkyPNG::Color.fade(color, 0xff - w)) if include_xy?(x0, y0 + 1)
          end
          point(x1, y1, color)
        end
        
        return self
      end
      
      alias_method :line, :line_xiaolin_wu
      
      # 
      def rect_naive(x0, y0, x1, y1, stroke = ChunkyPNG::Color::BLACK, brush = ChunkyPNG::Color::TRANSPARENT)
      
        # Fill
        unless brush == ChunkyPNG::Color::TRANSPARENT
          [x0, x1].min.upto([x0, x1].max) do |x|
            [y0, y1].min.upto([y0, y1].max) do |y|
              point(x, y, brush)
            end
          end
        end
        
        # Stroke
        line(x0, y0, x0, y1, stroke)
        line(x0, y1, x1, y1, stroke)
        line(x1, y1, x1, y0, stroke)
        line(x1, y0, x0, y0, stroke)
        
        return self
      end
      
      alias_method :rect, :rect_naive
      
      #
      def circle(x0, y0, radius, stroke = ChunkyPNG::Color::BLACK, brush = ChunkyPNG::Color::TRANSPARENT)
        
        # TODO: brush
        raise ChunkyPNG::NotSupported, "Circle fill brushes are not yet supported" unless brush == ChunkyPNG::Color::TRANSPARENT
        
        f = 1 - radius
        ddF_x = 1
        ddF_y = -2 * radius
        x = 0
        y = radius

        point(x0, y0 + radius, stroke)
        point(x0, y0 - radius, stroke)
        point(x0 + radius, y0, stroke)
        point(x0 - radius, y0, stroke)
        
        while x < y
          
          if f >= 0
            y -= 1
            ddF_y += 2
            f += ddF_y
          end

          x += 1
          ddF_x += 2
          f += ddF_x
          
          point(x0 + x, y0 + y, stroke)
          point(x0 - x, y0 + y, stroke)
          point(x0 + x, y0 - y, stroke)
          point(x0 - x, y0 - y, stroke)
          point(x0 + y, y0 + x, stroke)
          point(x0 - y, y0 + x, stroke)
          point(x0 + y, y0 - x, stroke)
          point(x0 - y, y0 - x, stroke)
        end
        return self
      end
    end
  end
end
