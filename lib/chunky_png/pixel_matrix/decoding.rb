module ChunkyPNG
  class PixelMatrix
    module Decoding
      
      def decode(ds)
        raise "Only 8-bit color depth is currently supported by ChunkyPNG!" unless ds.header_chunk.depth == 8
        
        stream     = Zlib::Inflate.inflate(ds.data_chunks.map(&:content).join(''))
        width      = ds.header_chunk.width
        height     = ds.header_chunk.height
        color_mode = ds.header_chunk.color
        interlace  = ds.header_chunk.interlace
        palette    = ChunkyPNG::Palette.from_chunks(ds.palette_chunk, ds.transparency_chunk)
        decode_pixelstream(stream, width, height, color_mode, palette, interlace)
      end
      
      def decode_pixelstream(stream, width, height, color_mode = ChunkyPNG::COLOR_TRUECOLOR, palette = nil, interlace = ChunkyPNG::INTERLACING_NONE)

        pixel_size = Pixel.bytesize(color_mode)
        
        raise "This palette is not suitable for decoding!" if palette && !palette.can_decode?

        pixel_decoder = case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR       then lambda { |bytes| ChunkyPNG::Pixel.rgb(*bytes) }
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA then lambda { |bytes| ChunkyPNG::Pixel.rgba(*bytes) }
          when ChunkyPNG::COLOR_INDEXED         then lambda { |bytes| palette[bytes.first] }
          when ChunkyPNG::COLOR_GRAYSCALE       then lambda { |bytes| ChunkyPNG::Pixel.grayscale(*bytes) }
          when ChunkyPNG::COLOR_GRAYSCALE_ALPHA then lambda { |bytes| ChunkyPNG::Pixel.grayscale(*bytes) }
          else raise "No suitable pixel decoder found for color mode #{color_mode}!"
        end
        
        if interlace == ChunkyPNG::INTERLACING_NONE
          pixels = decode_image_pass(stream, width, height, pixel_size, pixel_decoder)
        elsif interlace == ChunkyPNG::INTERLACING_ADAM7
          raise "NYI"
        else
          raise "Don't know how the handle interlacing method #{interlace}!"
        end
        return ChunkyPNG::PixelMatrix.new(width, height, pixels)
      end
      
      protected
      
      def decode_image_pass(stream, width, height, pixel_size, pixel_decoder)
        
        raise "Invalid stream length!" unless stream.length == width * height * pixel_size + height
        
        pixels = []
        decoded_bytes = Array.new(width * pixel_size, 0)
        height.times do |line_no|
        
          # get bytes of scanline
          position       = line_no * (width * pixel_size + 1)
          line_length    = width * pixel_size
          bytes          = stream.unpack("@#{position}CC#{line_length}")
          filter         = bytes.shift
          decoded_bytes  = decode_scanline(filter, bytes, decoded_bytes, pixel_size)
        
          # decode bytes into colors
          decoded_bytes.each_slice(pixel_size) { |bytes| pixels << pixel_decoder.call(bytes) }
        end
        pixels
      end
      
      def decode_adam7_interlacing()
        
      end
      
      def decode_scanline(filter, bytes, previous_bytes, pixelsize = 3)
        case filter
        when ChunkyPNG::FILTER_NONE    then decode_scanline_none(    bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_SUB     then decode_scanline_sub(     bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_UP      then decode_scanline_up(      bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_AVERAGE then decode_scanline_average( bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_PAETH   then decode_scanline_paeth(   bytes, previous_bytes, pixelsize)
        else raise "Unknown filter type"
        end
      end

      def decode_scanline_none(bytes, previous_bytes, pixelsize = 3)
        bytes
      end

      def decode_scanline_sub(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index { |b, i| bytes[i] = (b + (i >= pixelsize ? bytes[i-pixelsize] : 0)) % 256 }
        bytes
      end

      def decode_scanline_up(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index { |b, i| bytes[i] = (b + previous_bytes[i]) % 256 }
        bytes
      end

      def decode_scanline_average(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index do |byte, i|
          a = (i >= pixelsize) ? bytes[i - pixelsize] : 0
          b = previous_bytes[i]
          bytes[i] = (byte + (a + b / 2).floor) % 256
        end
        bytes
      end

      def decode_scanline_paeth(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index do |byte, i|
          a = (i >= pixelsize) ? bytes[i - pixelsize] : 0
          b = previous_bytes[i]
          c = (i >= pixelsize) ? previous_bytes[i - pixelsize] : 0
          p = a + b - c
          pa = (p - a).abs
          pb = (p - b).abs
          pc = (p - c).abs
          pr = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c)
          bytes[i] = (byte + pr) % 256
        end
        bytes
      end
    end
  end
end
