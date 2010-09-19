module ChunkyPNG
  class Canvas
    
    # The ChunkyPNG::Canvas::Operations module defines methods to perform operations
    # on a {ChunkyPNG::Canvas}. The module is included into the Canvas class so all
    # these methods are available on every canvas.
    #
    # Note that some of these operations modify the canvas, while some operations return 
    # a new canvas and leave the original intact.
    #
    # @see ChunkyPNG::Canvas
    module Operations
      
      # Composes another image onto this image using alpha blending.
      #
      # If you simply want to replace pixels or when the other image does not have
      # transparency, it is faster to use {#replace}.
      #
      # @param [ChunkyPNG::Canvas] other The foreground canvas to compose on the
      #     current canvas, using alpha compositing.
      # @param [Integer] offset_x The x-offset to apply the new forgeround on.
      # @param [Integer] offset_y The y-offset to apply the new forgeround on.
      # @return [ChunkyPNG::Canvas] Returns itself, but with the other canvas composed onto it.
      # @raise [ChunkyPNG::OutOfBounds] when the other canvas doesn't fit on this one,
      #     given the offset and size of the other canavs.
      # @see #replace
      def compose(other, offset_x = 0, offset_y = 0)
        check_size_constraints!(other, offset_x, offset_y)

        for y in 0...other.height do
          for x in 0...other.width do
            set_pixel(x + offset_x, y + offset_y, ChunkyPNG::Color.compose(other.get_pixel(x, y), get_pixel(x + offset_x, y + offset_y)))
          end
        end
        self
      end

      # Replaces pixels on this image by pixels from another pixels, on a given offset.
      #
      # This will completely replace the pixels of the background image. If you want to blend
      # them with semi-transparent pixels from the foreground image, see {#compose}.
      #
      # @return [ChunkyPNG::Canvas] Returns itself, but with the other canvas composed onto it.
      # @raise [ChunkyPNG::OutOfBounds] when the other canvas doesn't fit on this one,
      #     given the offset and size of the other canavs.
      # @see #compose
      def replace(other, offset_x = 0, offset_y = 0)
        check_size_constraints!(other, offset_x, offset_y)

        for y in 0...other.height do
          pixels[(y + offset_y) * width + offset_x, other.width] = other.pixels[y * other.width, other.width]
        end
        self
      end

      # Crops an image, given the coordinates and size of the image that needs to be cut out.
      # This will leave the original image intact and return a new, cropped image with pixels
      # copied from the original image.
      #
      # @param [Integer] x The x-coordinate of the top left corner of the image to be cropped.
      # @param [Integer] y The y-coordinate of the top left corner of the image to be cropped.
      # @param [Integer] crop_width The width of the image to be cropped.
      # @param [Integer] crop_height The height of the image to be cropped.
      # @return [ChunkyPNG::Canvas] Returns the newly created cropped image.
      # @raise [ChunkyPNG::OutOfBounds] when the crop dimensions plus the given coordinates 
      #     are bigger then the original image.
      def crop(x, y, crop_width, crop_height)
        
        raise ChunkyPNG::OutOfBounds, "Image width is too small!" if crop_width + x > width
        raise ChunkyPNG::OutOfBounds, "Image width is too small!" if crop_height + y > height
        
        new_pixels = []
        for cy in 0...crop_height do
          new_pixels += pixels.slice((cy + y) * width + x, crop_width)
        end
        ChunkyPNG::Canvas.new(crop_width, crop_height, new_pixels)
      end
      
      # Creates a new image, based on the current image but with a new theme color.
      #
      # This method will replace one color in an image with another image. This is done by
      # first extracting the pixels with a color close to the original theme color as a mask
      # image, changing the color of this mask image and then apply it on the original image.
      #
      # Mask extraction works best when the theme colored pixels are clearly distinguishable
      # from a background color (preferably white). You can set a tolerance level to influence
      # the extraction process.
      #
      # @param [Integer] old_theme_color The original theme color in this image.
      # @param [Integer] new_theme_color The color to replace the old theme color with.
      # @param [Integer] The backrgound color opn which the theme colored pixels are placed.
      # @param [Integer] tolerance The tolerance level to use when extracting the mask image. Five is 
      #    the default; increase this if the masked image does not extract all the required pixels, 
      #    decrease it if too many pixels get extracted.
      # @return [ChunkyPNG::Canvas] Returns itself, but with the theme colored pixels changed.
      # @see #change_theme_color!
      # @see #change_mask_color!
      def change_theme_color!(old_theme_color, new_theme_color, bg_color = ChunkyPNG::Color::WHITE, tolerance = 5)
        base, mask = extract_mask(old_theme_color, bg_color, tolerance)
        mask.change_mask_color!(new_theme_color)
        self.replace(base.compose(mask))
      end
      
      # Creates a base image and a mask image from an original image that has a particular theme color.
      # This can be used to easily change a theme color in an image.
      #
      # It will extract all the pixels that look like the theme color (with a tolerance level) and put
      # these in a mask image. All the other pixels will be stored in a base image. Both images will be
      # of the exact same size as the original image. The original image will be left untouched.
      #
      # The color of the mask image can be changed with {#change_mask_color!}. This new mask image can 
      # then be composed upon the base image to create an image with a new theme color. A call to 
      # {#change_theme_color!} will perform this in one go.
      #
      # @param [Integer] mask_color The current theme color.
      # @param [Integer] bg_color The background color on which the theme colored pxiels are applied.
      # @param [Integer] tolerance The tolerance level to use when extracting the mask image. Five is 
      #    the default; increase this if the masked image does not extract all the required pixels, 
      #    decrease it if too many pixels get extracted.
      # @return [Array<ChunkyPNG::Canvas, ChunkyPNG::Canvas>] An array with the base canvas and the mask 
      #    canvas as elements.
      # @see #change_theme_color!
      # @see #change_mask_color!
      def extract_mask(mask_color, bg_color = ChunkyPNG::Color::WHITE, tolerance = 5)
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
      
      # Changes the color of a mask image.
      #
      # This method works on acanavs extracte out of another image using the {#extract_mask} method.
      # It can then be applied on the extracted base image. See {#change_theme_color!} to perform
      # these operations in one go.
      #
      # @param [Integer] new_color The color to replace the original mask color with.
      # @raise [ChunkyPNG::ExpectationFailed] when this canvas is not a mask image, i.e. its palette
      #    has more than once color, disregarding transparency.
      # @see #change_theme_color!
      # @see #extract_mask
      def change_mask_color!(new_color)
        raise ChunkyPNG::ExpectationFailed, "This is not a mask image!" if palette.opaque_palette.size != 1
        pixels.map! { |pixel| (new_color & 0xffffff00) | ChunkyPNG::Color.a(pixel) }
        self
      end
      
      # Flips the image horizontally.
      #
      # This will flip the image on its horizontal axis, e.g. pixels on the top will now
      # be pixels on the bottom. Chaining this method twice will return the original canvas.
      # This method will leave the original object intact and return a new canvas.
      #
      # @return [ChunkyPNG::Canvas] The flipped image
      def flip_horizontally
        self.class.new(width, height).tap do |flipped|
          for y in 0...height do
            flipped.replace_row!(height - (y + 1), row(y))
          end
        end
      end
      
      # Flips the image horizontally.
      #
      # This will flip the image on its vertical axis, e.g. pixels on the left will now
      # be pixels on the right. Chaining this method twice will return the original canvas.
      # This method will leave the original object intact and return a new canvas.
      #
      # @return [ChunkyPNG::Canvas] The flipped image
      def flip_vertically
        self.class.new(width, height).tap do |flipped|
          for x in 0...width do
            flipped.replace_column!(width - (x + 1), column(x))
          end
        end
      end

      # Rotates the image 90 degrees clockwise.
      # This method will leave the original object intact and return a new canvas.
      #
      # @return [ChunkyPNG::Canvas] The rotated image
      def rotate_right
        self.class.new(height, width).tap do |rotated|
          for i in 0...width do
            rotated.replace_row!(i, column(i).reverse)
          end
        end
      end
      
      # Rotates the image 90 degrees counter-clockwise.
      # This method will leave the original object intact and return a new canvas.
      #
      # @return [ChunkyPNG::Canvas] The rotated image.
      def rotate_left
        self.class.new(height, width).tap do |rotated|
          for i in 0...width do
            rotated.replace_row!(width - (i + 1), column(i))
          end
        end
      end
      
      # Rotates the image 180 degrees.
      # This method will leave the original object intact and return a new canvas.
      #
      # @return [ChunkyPNG::Canvas] The rotated image.
      def rotate_180
        self.class.new(width, height).tap do |flipped|
          for y in 0...height do
            flipped.replace_row!(height - (y + 1), row(y).reverse)
          end
        end
      end

      protected
      
      # Checks whether another image has the correct dimension to be used for an operation
      # on the current image, given an offset coordinate to work with.
      # @param [ChunkyPNG::Canvas] other The other canvas
      # @param [Integer] offset_x The x offset on which the other image will be applied.
      # @param [Integer] offset_y The y offset on which the other image will be applied.
      # @raise [ChunkyPNG::OutOfBounds] when the other image doesn't fit.
      def check_size_constraints!(other, offset_x, offset_y)
        raise ChunkyPNG::OutOfBounds, "Background image width is too small!"  if width  < other.width  + offset_x
        raise ChunkyPNG::OutOfBounds, "Background image height is too small!" if height < other.height + offset_y
      end
    end
  end
end
