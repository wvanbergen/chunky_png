module ChunkyPNG
  class Canvas
    
    # Methods for decoding and encoding adam7 interlacing
    #
    module Adam7Interlacing
      
      def adam7_multiplier_offset(pass)
        [3 - (pass >> 1), (pass & 1 == 0) ? 0 : 8 >> ((pass + 1) >> 1),
         pass == 0 ? 3 : 3 - ((pass - 1) >> 1), (pass == 0 || pass & 1 == 1) ? 0 : 8 >> (pass >> 1)]
      end

      def adam7_pass_size(pass, original_width, original_height)
        x_shift, x_offset, y_shift, y_offset = adam7_multiplier_offset(pass)
        [ (original_width  - x_offset + (1 << x_shift) - 1) >> x_shift,
          (original_height - y_offset + (1 << y_shift) - 1) >> y_shift]
      end

      def adam7_pass_sizes(original_width, original_height)
        (0...7).map { |pass| adam7_pass_size(pass, original_width, original_height) }
      end

      def adam7_merge_pass(pass, canvas, subcanvas)
        x_shift, x_offset, y_shift, y_offset = adam7_multiplier_offset(pass)
        for y in 0...subcanvas.height do
          for x in 0...subcanvas.width do
            new_x = (x << x_shift) | x_offset
            new_y = (y << y_shift) | y_offset
            canvas[new_x, new_y] = subcanvas[x, y]
          end
        end
        canvas
      end
      
      def adam7_extract_pass(pass, canvas)
        x_shift, x_offset, y_shift, y_offset = adam7_multiplier_offset(pass)
        sm_pixels = []
        
        y_offset.step(canvas.height - 1, 1 << y_shift) do |y|
          x_offset.step(canvas.width - 1, 1 << x_shift) do |x|
            sm_pixels << canvas[x, y]
          end
        end
        
        new_canvas_args = adam7_pass_size(pass, canvas.width, canvas.height) + [sm_pixels]
        ChunkyPNG::Canvas.new(*new_canvas_args)
      end
    end
  end
end
