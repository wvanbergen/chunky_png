module ChunkyPNG
  class Canvas
    module Operations
      def compose(new_foreground, dx = 0, dy = 0)
        check_size_constraints!(new_foreground, dx, dy)

        for y in 0...new_foreground.height do
          for x in 0...new_foreground.width do
            self[x+dx, y+dy] = ChunkyPNG::Color.compose(new_foreground[x, y], self[x+dx, y+dy])
          end
        end
        self
      end

      def replace(other, offset_x = 0, offset_y = 0)
        check_size_constraints!(other, offset_x, offset_y)

        for y in 0...other.height do
          pixels[(y + offset_y) * width + offset_x, other.width] = other.pixels[y * other.width, other.width]
        end
        self
      end

      def crop(x, y, crop_width, crop_height)
        new_pixels = []
        for cy in 0...crop_height do
          new_pixels += pixels.slice((cy + y) * width + x, crop_width)
        end
        ChunkyPNG::Canvas.new(crop_width, crop_height, new_pixels)
      end
      
      def change_theme_color!(old_theme_color, new_theme_color, bg_color = ChunkyPNG::Color::WHITE, tolerance = 5)
        base, mask = extract_mask(old_theme_color, bg_color, tolerance)
        mask.change_mask_color!(new_theme_color)
        self.replace(base.compose(mask))
      end
      
      def extract_mask(mask_color, bg_color, tolerance = 5)
        base_pixels = []
        mask_pixels = []

        pixels.each do |pixel|
          if ChunkyPNG::Color.alpha_decomposable?(pixel, mask_color, bg_color, tolerance)
            mask_pixels << ChunkyPNG::Color.decompose_color(pixel, mask_color, bg_color, tolerance)
            base_pixels << bg_color
          else
            mask_pixels << (mask_color & 0xffffff00)
            base_pixels << pixel
          end
        end
        
        [ self.class.new(width, height, base_pixels), self.class.new(width, height, mask_pixels) ]
      end
      
      def change_mask_color!(new_color)
        raise ChunkyPNG::ExpectationFailed, "This is not a mask image!" if palette.opaque_palette.size != 1
        pixels.map! { |pixel| (new_color & 0xffffff00) | ChunkyPNG::Color.a(pixel) }
      end

      protected

      def check_size_constraints!(other, offset_x, offset_y)
        raise ChunkyPNG::ExpectationFailed, "Background image width is too small!"  if width  < other.width  + offset_x
        raise ChunkyPNG::ExpectationFailed, "Background image height is too small!" if height < other.height + offset_y
      end
    end
  end
end
