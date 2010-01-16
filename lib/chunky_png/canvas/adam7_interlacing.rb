module ChunkyPNG
  class Canvas
    
    # Methods for decoding and encoding adam7 interlacing
    #
    module Adam7Interlacing
      
      def adam7_multiplier_offset(pass)
        {
          :x_multiplier => 8 >> (pass >> 1),
          :x_offset     => (pass & 1 == 0) ? 0 : 8 >> ((pass + 1) >> 1),
          :y_multiplier => pass == 0 ? 8 : 8 >> ((pass - 1) >> 1),
          :y_offset     => (pass == 0 || pass & 1 == 1) ? 0 : 8 >> (pass >> 1)
        }
      end

      def adam7_pass_size(pass, original_width, original_height)
        m_o = adam7_multiplier_offset(pass)
        [ ((original_width  - m_o[:x_offset] ) / m_o[:x_multiplier].to_f).ceil,
          ((original_height - m_o[:y_offset] ) / m_o[:y_multiplier].to_f).ceil]
      end

      def adam7_pass_sizes(original_width, original_height)
        (0...7).map { |pass| adam7_pass_size(pass, original_width, original_height) }
      end

      def adam7_merge_pass(pass, canvas, subcanvas)
        m_o = adam7_multiplier_offset(pass)
        for y in 0...subcanvas.height do
          for x in 0...subcanvas.width do
            new_x = x * m_o[:x_multiplier] + m_o[:x_offset]
            new_y = y * m_o[:y_multiplier] + m_o[:y_offset]
            canvas[new_x, new_y] = subcanvas[x, y]
          end
        end
        canvas
      end
      
      def adam7_extract_pass(pass, canvas)
        m_o = adam7_multiplier_offset(pass)
        sm_pixels = []
        m_o[:y_offset].step(canvas.height - 1, m_o[:y_multiplier]) do |y|
          m_o[:x_offset].step(canvas.width - 1, m_o[:x_multiplier]) do |x|
            sm_pixels << canvas[x, y]
          end
        end
        
        new_canvas_args = adam7_pass_size(pass, canvas.width, canvas.height) + [sm_pixels]
        ChunkyPNG::Canvas.new(*new_canvas_args)
      end
    end
  end
end
