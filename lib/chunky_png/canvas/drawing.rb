module ChunkyPNG
  class Canvas
    
    module Drawing
      
      # Sets a point on the canvas by composing a pixel with its background color.
      def point(x, y, color)
        set_pixel(x, y, ChunkyPNG::Color.compose(color, get_pixel(x, y)))
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
      
      def rect(x0, y0, x1, y1, line_color, fill_color = ChunkyPNG::COLOR::TRANSPARENT)
      
        # Fill
        [x0, x1].min.upto([x0, x1].max) do |x|
          [y0, y1].min.upto([y0, y1].max) do |y|
            point(x, y, fill_color)
          end
        end
        
        # Stroke
        line(x0, y0, x0, y1, line_color)
        line(x0, y1, x1, y1, line_color)
        line(x1, y1, x1, y0, line_color)
        line(x1, y0, x0, y0, line_color)
        
        return self
      end
    end
  end
end
