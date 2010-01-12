module ChunkyPNG
  class PixelMatrix
    module Decoding
      
      def decode(ds)
        stream     = Zlib::Inflate.inflate(ds.data_chunks.map(&:content).join(''))
        width      = ds.header_chunk.width
        height     = ds.header_chunk.height
        color_mode = ds.header_chunk.color
        palette    = ChunkyPNG::Palette.from_chunks(ds.palette_chunk, ds.transparency_chunk)
        decode_pixelstream(stream, width, height, color_mode, palette)
      end
      
      def decode_pixelstream(stream, width, height, color_mode = ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR, palette = nil)

        pixel_size = Pixel.bytesize(color_mode)
        raise "Invalid stream length!" unless stream.length == width * height * pixel_size + height
        raise "This palette is not suitable for decoding!" if palette && !palette.can_decode?

        pixel_decoder = case color_mode
          when ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR       then lambda { |bytes| ChunkyPNG::Pixel.rgb(*bytes) }
          when ChunkyPNG::Chunk::Header::COLOR_TRUECOLOR_ALPHA then lambda { |bytes| ChunkyPNG::Pixel.rgba(*bytes) }
          when ChunkyPNG::Chunk::Header::COLOR_INDEXED         then lambda { |bytes| palette[bytes.first] }
          when ChunkyPNG::Chunk::Header::COLOR_GRAYSCALE       then lambda { |bytes| ChunkyPNG::Pixel.grayscale(*bytes) }
          when ChunkyPNG::Chunk::Header::COLOR_GRAYSCALE_ALPHA then lambda { |bytes| ChunkyPNG::Pixel.grayscale(*bytes) }
          else raise "No suitable pixel decoder found for color mode #{color_mode}!"
        end
        
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
        
        return ChunkyPNG::PixelMatrix.new(width, height, pixels)
      end
      
      protected
      
      def decode_scanline(filter, bytes, previous_bytes, pixelsize = 3)
        case filter
        when FILTER_NONE    then decode_scanline_none( bytes, previous_bytes, pixelsize)
        when FILTER_SUB     then decode_scanline_sub(  bytes, previous_bytes, pixelsize)
        when FILTER_UP      then decode_scanline_up(   bytes, previous_bytes, pixelsize)
        when FILTER_AVERAGE then raise "Average filter are not yet supported!"
        when FILTER_PAETH   then raise "Paeth filter are not yet supported!"
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
    end
  end
end
