module ChunkyPNG
  class PixelMatrix
    module Operations
      def compose(other, dx = 0, dy = 0)
        check_size_constraints!(other, dx, dy)

        other.height.times do |y|
          other.width.times do |x|
            self[x+dx, y+dy] = self[x+dx, y+dy] & other[x, y]
          end
        end
        self
      end

      def replace(other, offset_x = 0, offset_y = 0)
        check_size_constraints!(other, offset_x, offset_y)

        other.height.times do |y|
          pixels[(y + offset_y) * width + offset_x, other.width] = other.pixels[y * other.width, other.width]
        end
        self
      end

      def crop(x, y, crop_width, crop_height)
        new_pixels = []
        crop_height.times do |cy|
          new_pixels += pixels.slice((cy + y) * width + x, crop_width)
        end
        ChunkyPNG::PixelMatrix.new(crop_width, crop_height, new_pixels)
      end

      protected

      def check_size_constraints!(other, offset_x, offset_y)
        raise "Background image width is too small!"  if width  < other.width  + offset_x
        raise "Background image height is too small!" if height < other.height + offset_y
      end
    end
  end
end
