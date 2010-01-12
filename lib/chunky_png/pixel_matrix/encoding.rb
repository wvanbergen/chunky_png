module ChunkyPNG
  class PixelMatrix
    module Encoding

      def encode(constraints = {})
        encoding = determine_encoding(constraints)
        result = {}
        result[:header] = { :width => width, :height => height, :color => encoding[:color_mode] }

        if encoding[:color_mode] == ChunkyPNG::Chunk::Header::COLOR_INDEXED
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
      
      def encode_pixelstream(color_mode = ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR, palette = nil)

        pixel_encoder = case color_mode
          when ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR       then lambda { |pixel| pixel.to_truecolor_bytes }
          when ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR_ALPHA then lambda { |pixel| pixel.to_truecolor_alpha_bytes }
          when ChunkyPNG::Chunk::Header::COLOR_INDEXED         then lambda { |pixel| pixel.to_indexed_bytes(palette) }
          when ChunkyPNG::Chunk::Header::COLOR_GRAYSCALE       then lambda { |pixel| pixel.to_grayscale_bytes }
          when ChunkyPNG::Chunk::Header::COLOR_GRAYSCALE_ALPHA then lambda { |pixel| pixel.to_grayscale_alpha_bytes }
          else raise "Cannot encode pixels for this mode: #{color_mode}!"
        end
        
        if color_mode == ChunkyPNG::Chunk::Header::COLOR_INDEXED && !palette.can_encode?
          raise "This palette is not suitable for encoding!"
        end

        pixelsize = Pixel.bytesize(color_mode)

        stream   = ""
        previous = nil
        each_scanline do |line|
          bytes  = line.map(&pixel_encoder).flatten
          if previous
            stream << encode_scanline_up(bytes, previous, pixelsize).pack('C*')
          else
            stream << encode_scanline_sub(bytes, previous, pixelsize).pack('C*')
          end
          previous = bytes
        end
        return stream
      end      

      def encode_scanline(filter, bytes, previous_bytes = nil, pixelsize = 3)
        case filter
        when FILTER_NONE    then encode_scanline_none( bytes, previous_bytes, pixelsize)
        when FILTER_SUB     then encode_scanline_sub(  bytes, previous_bytes, pixelsize)
        when FILTER_UP      then encode_scanline_up(   bytes, previous_bytes, pixelsize)
        when FILTER_AVERAGE then raise "Average filter are not yet supported!"
        when FILTER_PAETH   then raise "Paeth filter are not yet supported!"
        else raise "Unknown filter type"
        end
      end

      def encode_scanline_none(bytes, previous_bytes = nil, pixelsize = 3)
        [FILTER_NONE] + bytes
      end

      def encode_scanline_sub(bytes, previous_bytes = nil, pixelsize = 3)
        encoded = (pixelsize...bytes.length).map { |n| (bytes[n-pixelsize] - bytes[n]) % 256 }
        [FILTER_SUB] + bytes[0...pixelsize] + encoded
      end

      def encode_scanline_up(bytes, previous_bytes, pixelsize = 3)
        encoded = (0...bytes.length).map { |n| previous_bytes[n] - bytes[n] % 256 }
        [FILTER_UP] + encoded
      end
    end
  end
end
