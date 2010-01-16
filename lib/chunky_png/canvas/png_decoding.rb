module ChunkyPNG
  class Canvas
    
    # The PNGDecoding contains methods for decoding PNG datastreams to create a Canvas object.
    # The datastream can be provided as filename, string or IO object.
    module PNGDecoding

      attr_accessor :decoding_palette

      def from_blob(str)
        from_datastream(ChunkyPNG::Datastream.from_blob(str))
      end
      
      alias :from_string :from_blob

      def from_file(filename)
        from_datastream(ChunkyPNG::Datastream.from_file(filename))
      end
      
      def from_io(io)
        from_datastream(ChunkyPNG::Datastream.from_io(io))
      end

      def from_datastream(ds)
        raise "Only 8-bit color depth is currently supported by ChunkyPNG!" unless ds.header_chunk.depth == 8

        width      = ds.header_chunk.width
        height     = ds.header_chunk.height
        color_mode = ds.header_chunk.color
        interlace  = ds.header_chunk.interlace
        
        self.decoding_palette = ChunkyPNG::Palette.from_chunks(ds.palette_chunk, ds.transparency_chunk)
        pixelstream           = ChunkyPNG::Chunk::ImageData.combine_chunks(ds.data_chunks)
        
        decode_png_pixelstream(pixelstream, width, height, color_mode, interlace)
      end

      def decode_png_pixelstream(stream, width, height, color_mode = ChunkyPNG::COLOR_TRUECOLOR, interlace = ChunkyPNG::INTERLACING_NONE)
        raise "This palette is not suitable for decoding!" if decoding_palette && !decoding_palette.can_decode?

        return case interlace
          when ChunkyPNG::INTERLACING_NONE  then decode_png_without_interlacing(stream, width, height, color_mode)
          when ChunkyPNG::INTERLACING_ADAM7 then decode_png_with_adam7_interlacing(stream, width, height, color_mode)
          else raise "Don't know how the handle interlacing method #{interlace}!"
        end
      end

      protected

      def decode_png_without_interlacing(stream, width, height, color_mode)
        decode_png_image_pass(stream, width, height, color_mode)
      end

      def decode_png_with_adam7_interlacing(stream, width, height, color_mode)
        canvas     = ChunkyPNG::Canvas.new(width, height)
        pixel_size = Color.bytesize(color_mode)
        start_pos  = 0
        for pass in 0...7 do
          sm_width, sm_height = adam7_pass_size(pass, width, height)
          sm = decode_png_image_pass(stream, sm_width, sm_height, color_mode, start_pos)
          adam7_merge_pass(pass, canvas, sm)
          start_pos += (sm_width * sm_height * pixel_size) + sm_height
        end
        canvas
      end

      def decode_png_image_pass(stream, width, height, color_mode, start_pos = 0)
        
        pixel_size    = Color.bytesize(color_mode)
        pixel_decoder = case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR       then lambda { |bytes| ChunkyPNG::Color.rgb(*bytes) }
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA then lambda { |bytes| ChunkyPNG::Color.rgba(*bytes) }
          when ChunkyPNG::COLOR_INDEXED         then lambda { |bytes| decoding_palette[bytes.first] }
          when ChunkyPNG::COLOR_GRAYSCALE       then lambda { |bytes| ChunkyPNG::Color.grayscale(*bytes) }
          when ChunkyPNG::COLOR_GRAYSCALE_ALPHA then lambda { |bytes| ChunkyPNG::Color.grayscale_alpha(*bytes) }
          else raise "No suitable pixel decoder found for color mode #{color_mode}!"
        end
        
        pixels = []
        if width > 0
          
          raise "Invalid stream length!" unless stream.length - start_pos >= width * height * pixel_size + height
          
          decoded_bytes = Array.new(width * pixel_size, 0)
          for line_no in 0...height do

            # get bytes of scanline
            position       = start_pos + line_no * (width * pixel_size + 1)
            line_length    = width * pixel_size
            bytes          = stream.unpack("@#{position}CC#{line_length}")
            filter         = bytes.shift
            decoded_bytes  = decode_png_scanline(filter, bytes, decoded_bytes, pixel_size)

            # decode bytes into colors
            decoded_bytes.each_slice(pixel_size) { |bytes| pixels << pixel_decoder.call(bytes) }
          end
        end
        
        new(width, height, pixels)
      end



      def decode_png_scanline(filter, bytes, previous_bytes, pixelsize = 3)
        case filter
        when ChunkyPNG::FILTER_NONE    then decode_png_scanline_none(    bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_SUB     then decode_png_scanline_sub(     bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_UP      then decode_png_scanline_up(      bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_AVERAGE then decode_png_scanline_average( bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_PAETH   then decode_png_scanline_paeth(   bytes, previous_bytes, pixelsize)
        else raise "Unknown filter type"
        end
      end

      def decode_png_scanline_none(bytes, previous_bytes, pixelsize = 3)
        bytes
      end

      def decode_png_scanline_sub(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index { |b, i| bytes[i] = (b + (i >= pixelsize ? bytes[i-pixelsize] : 0)) % 256 }
        bytes
      end

      def decode_png_scanline_up(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index { |b, i| bytes[i] = (b + previous_bytes[i]) % 256 }
        bytes
      end

      def decode_png_scanline_average(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index do |byte, i|
          a = (i >= pixelsize) ? bytes[i - pixelsize] : 0
          b = previous_bytes[i]
          bytes[i] = (byte + ((a + b) >> 1)) % 256
        end
        bytes
      end

      def decode_png_scanline_paeth(bytes, previous_bytes, pixelsize = 3)
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
