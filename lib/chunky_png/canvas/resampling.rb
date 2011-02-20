module ChunkyPNG
  class Canvas
    
    # The ChunkyPNG::Canvas::Resampling module defines methods to perform image resampling to 
    # a {ChunkyPNG::Canvas}.
    #
    # @see ChunkyPNG::Canvas
    module Resampling
      
      # Resamples an image. This will return a new canvas instance.
      def resample_nearest_neighbor(new_width, new_height)
        
        resampled_image = self.class.new(new_width.to_i, new_height.to_i)
        
        width_ratio  = width.to_f / new_width.to_f
        height_ratio = height.to_f / new_height.to_f

        for y in 1..new_height do
          source_y   = (y - 0.5) * height_ratio + 0.5
          input_y    = source_y.to_i

          for x in 1..new_width do
            source_x = (x - 0.5) * width_ratio + 0.5
            input_x  = source_x.to_i

            resampled_image.set_pixel(x - 1, y - 1, self[[input_x - 1, 0].max, [input_y - 1, 0].max])
          end
        end
        
        return resampled_image
      end
      
      alias_method :resample, :resample_nearest_neighbor
    end
  end
end
