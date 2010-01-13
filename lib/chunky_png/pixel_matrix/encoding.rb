module ChunkyPNG
  class PixelMatrix
    module Encoding

      def encode(constraints = {})
        encoding = determine_encoding(constraints)
        result = {}
        result[:header] = { :width => width, :height => height, :color => encoding[:color_mode] }

        if encoding[:color_mode] == ChunkyPNG::COLOR_INDEXED
          result[:palette_chunk]      = encoding[:palette].to_plte_chunk
          result[:transparency_chunk] = encoding[:palette].to_trns_chunk unless encoding[:palette].opaque?
        end

        result[:pixelstream] = encode_pixelstream(encoding[:color_mode], encoding[:palette])
        return result
      end
      
      protected
      
      def determine_encoding(constraints = {})
        encoding = constraints
        encoding[:palette]    ||= palette
        encoding[:color_mode] ||= encoding[:palette].best_colormode
        return encoding
      end
      
      def encode_pixelstream(color_mode = ChunkyPNG::COLOR_TRUECOLOR, palette = nil)

        pixel_encoder = case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR       then lambda { |pixel| pixel.to_truecolor_bytes }
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA then lambda { |pixel| pixel.to_truecolor_alpha_bytes }
          when ChunkyPNG::COLOR_INDEXED         then lambda { |pixel| pixel.to_indexed_bytes(palette) }
          when ChunkyPNG::COLOR_GRAYSCALE       then lambda { |pixel| pixel.to_grayscale_bytes }
          when ChunkyPNG::COLOR_GRAYSCALE_ALPHA then lambda { |pixel| pixel.to_grayscale_alpha_bytes }
          else raise "Cannot encode pixels for this mode: #{color_mode}!"
        end
        
        if color_mode == ChunkyPNG::COLOR_INDEXED && !palette.can_encode?
          raise "This palette is not suitable for encoding!"
        end

        pixel_size = Pixel.bytesize(color_mode)

        stream   = ""
        previous_bytes = Array.new(pixel_size * width, 0)
        each_scanline do |line|
          unencoded_bytes = line.map(&pixel_encoder).flatten
          stream << encode_scanline_up(unencoded_bytes, previous_bytes, pixel_size).pack('C*')
          previous_bytes  = unencoded_bytes
        end
        return stream
      end

      def encode_scanline(filter, bytes, previous_bytes = nil, pixelsize = 3)
        case filter
        when ChunkyPNG::FILTER_NONE    then encode_scanline_none( bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_SUB     then encode_scanline_sub(  bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_UP      then encode_scanline_up(   bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_AVERAGE then raise "Average filter are not yet supported!"
        when ChunkyPNG::FILTER_PAETH   then raise "Paeth filter are not yet supported!"
        else raise "Unknown filter type"
        end
      end

      def encode_scanline_none(original_bytes, previous_bytes = nil, pixelsize = 3)
        [ChunkyPNG::FILTER_NONE] + original_bytes
      end

      def encode_scanline_sub(original_bytes, previous_bytes = nil, pixelsize = 3)
        encoded_bytes = []
        original_bytes.length.times do |index|
          a = (index >= pixelsize) ? original_bytes[index - pixelsize] : 0
          encoded_bytes[index] = (original_bytes[index] - a) % 256
        end
        [ChunkyPNG::FILTER_SUB] + encoded_bytes
      end

      def encode_scanline_up(original_bytes, previous_bytes, pixelsize = 3)
        encoded_bytes = []
        original_bytes.length.times do |index|
          b = previous_bytes[index]
          encoded_bytes[index] = (original_bytes[index] - b) % 256
        end
        [ChunkyPNG::FILTER_UP] + encoded_bytes
      end
    end
  end
end
