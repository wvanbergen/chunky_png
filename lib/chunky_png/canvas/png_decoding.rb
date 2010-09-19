module ChunkyPNG
  class Canvas

    # The PNGDecoding contains methods for decoding PNG datastreams to create a 
    # Canvas object. The datastream can be provided as filename, string or IO 
    # stream.
    #
    # Overview of the decoding process:
    #
    # * The optional PLTE and tRNS chunk are decoded for the color palette of
    #   the original image.
    # * The contents of the IDAT chunks is combined, and uncompressed using
    #   Inflate decompression to the image pixelstream.
    # * Based on the color mode, width and height of the original image, which
    #   is read from the PNG header (IHDR chunk), the amount of bytes
    #   per line is determined.
    # * For every line of pixels in the encoded image, the original byte values
    #   are restored by unapplying the milter method for that line.
    # * The read bytes are unfiltered given by the filter function specified by
    #   the first byte of the line.
    # * The unfiltered pixelstream are is into colored pixels, using the color mode.
    # * All lines combined to form the original image.
    #
    # For interlaced images, the original image was split into 7 subimages.
    # These images get decoded just like the process above (from step 3), and get 
    # combined to form the original images.
    #
    # @see ChunkyPNG::Canvas::PNGEncoding
    # @see http://www.w3.org/TR/PNG/ The W3C PNG format specification
    module PNGDecoding

      # The palette that is used to decode the image, loading from the PLTE and
      # tRNS chunk from the PNG stream. For RGB(A) images, no palette is required.
      # @return [ChunkyPNG::Palette]
      attr_accessor :decoding_palette

      # Decodes a Canvas from a PNG encoded string.
      # @param [String] str The string to read from.
      # @return [ChunkyPNG::Canvas] The canvas decoded from the PNG encoded string.
      def from_blob(str)
        from_datastream(ChunkyPNG::Datastream.from_blob(str))
      end

      alias :from_string :from_blob

      # Decodes a Canvas from a PNG encoded file.
      # @param [String] filename The file to read from.
      # @return [ChunkyPNG::Canvas] The canvas decoded from the PNG file.
      def from_file(filename)
        from_datastream(ChunkyPNG::Datastream.from_file(filename))
      end

      # Decodes a Canvas from a PNG encoded stream.
      # @param [IO, #read] io The stream to read from.
      # @return [ChunkyPNG::Canvas] The canvas decoded from the PNG stream.
      def from_io(io)
        from_datastream(ChunkyPNG::Datastream.from_io(io))
      end

      # Decodes the Canvas from a PNG datastream instance.
      # @param [ChunkyPNG::Datastream] ds The datastream to decode.
      # @return [ChunkyPNG::Canvas] The canvas decoded from the PNG datastream.
      def from_datastream(ds)
        raise ChunkyPNG::NotSupported, "Only 8-bit color depth is currently supported by ChunkyPNG!" unless ds.header_chunk.depth == 8

        width      = ds.header_chunk.width
        height     = ds.header_chunk.height
        color_mode = ds.header_chunk.color
        interlace  = ds.header_chunk.interlace

        self.decoding_palette = ChunkyPNG::Palette.from_chunks(ds.palette_chunk, ds.transparency_chunk)
        pixelstream           = ChunkyPNG::Chunk::ImageData.combine_chunks(ds.data_chunks)

        decode_png_pixelstream(pixelstream, width, height, color_mode, interlace)
      end

      # Decodes a canvas from a PNG encoded pixelstream, using a given width, height, 
      # color mode and interlacing mode.
      # @param [String] stream The pixelstream to read from.
      # @param [Integer] width The width of the image.
      # @param [Integer] width The height of the image.
      # @param [Integer] color_mode The color mode of the encoded pixelstream.
      # @param [Integer] interlace The interlace method of the encoded pixelstream.
      # @return [ChunkyPNG::Canvas] The decoded Canvas instance.
      def decode_png_pixelstream(stream, width, height, color_mode = ChunkyPNG::COLOR_TRUECOLOR, interlace = ChunkyPNG::INTERLACING_NONE)
        raise ChunkyPNG::ExpectationFailed, "This palette is not suitable for decoding!" if decoding_palette && !decoding_palette.can_decode?

        return case interlace
          when ChunkyPNG::INTERLACING_NONE;  decode_png_without_interlacing(stream, width, height, color_mode)
          when ChunkyPNG::INTERLACING_ADAM7; decode_png_with_adam7_interlacing(stream, width, height, color_mode)
          else raise ChunkyPNG::NotSupported, "Don't know how the handle interlacing method #{interlace}!"
        end
      end

      protected

      # Decodes a canvas from a non-interlaced PNG encoded pixelstream, using a 
      # given width, height and color mode.
      # @param stream (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param width (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param height (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param color_mode (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      def decode_png_without_interlacing(stream, width, height, color_mode)
        decode_png_image_pass(stream, width, height, color_mode)
      end

      # Decodes a canvas from a Adam 7 interlaced PNG encoded pixelstream, using a 
      # given width, height and color mode.
      # @param stream (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param width (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param height (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param color_mode (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      def decode_png_with_adam7_interlacing(stream, width, height, color_mode)
        canvas     = new(width, height)
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

      # Decodes a single PNG image pass width a given width, height and color 
      # mode, to a Canvas, starting at the given position in the stream.
      #
      # A non-interlaced image only consists of one pass, while an Adam7
      # image consists of 7 passes that must be combined after decoding.
      #
      # @param stream (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param width (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param height (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param color_mode (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      # @param [Integer] start_pos The position in the pixel stream to start reading.
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_pixelstream)
      def decode_png_image_pass(stream, width, height, color_mode, start_pos = 0)
        stream << ChunkyPNG::EXTRA_BYTE if color_mode == ChunkyPNG::COLOR_TRUECOLOR
        pixel_size    = Color.bytesize(color_mode)
        pixel_decoder = case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR;       lambda { |s, pos| s.unpack("@#{pos + 1}" << ('NX' * width)).map { |c| c | 0x000000ff } }
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA; lambda { |s, pos| s.unpack("@#{pos + 1}N#{width}") }
          when ChunkyPNG::COLOR_INDEXED;         lambda { |s, pos| (1..width).map { |i| decoding_palette[s.getbyte(pos + i)] } }
          when ChunkyPNG::COLOR_GRAYSCALE;       lambda { |s, pos| (1..width).map { |i| ChunkyPNG::Color.grayscale(s.getbyte(pos + i)) } }
          when ChunkyPNG::COLOR_GRAYSCALE_ALPHA; lambda { |s, pos| (0...width).map { |i| ChunkyPNG::Color.grayscale_alpha(s.getbyte(pos + (i * 2) + 1), s.getbyte(pos + (i * 2) + 2)) } }
          else raise ChunkyPNG::NotSupported, "No suitable pixel decoder found for color mode #{color_mode}!"
        end
        
        pixels = []
        if width > 0
          
          raise ChunkyPNG::ExpectationFailed, "Invalid stream length!" unless stream.length - start_pos >= width * height * pixel_size + height
          
          decoded_bytes = Array.new(width * pixel_size, 0)
          line_length    = width * pixel_size
          pos, prev_pos  = start_pos, nil

          for line_no in 0...height do
            decode_png_str_scanline(stream, pos, prev_pos, line_length, pixel_size)
            pixels += pixel_decoder.call(stream, pos)

            prev_pos = pos
            pos += line_length + 1
          end
        end
        
        new(width, height, pixels)
      end

      # Decodes a scanline if it was encoded using filtering. 
      #
      # It will extract the filtering method from the first byte of the scanline, and uses the 
      # method to change the subsequent bytes to unfiltered values. This will modify the pixelstream.
      #
      # The bytes of the scanline can then be used to construct pixels, based on the color mode..
      #
      # @param [String] stream The pixelstream to undo the filtering in.
      # @param [Integer] pos The starting position of the scanline to decode.
      # @param [Integer, nil] prev_pos The starting position of the previously decoded scanline, or <tt>nil</tt>
      #     if this is the first scanline of the image.
      # @param [Integer] line_length The number of bytes in the scanline, discounting the filter method byte.
      # @param [Integer] pixel_size The number of bytes used per pixel, based on the color mode.
      # @return [nil]
      def decode_png_str_scanline(stream, pos, prev_pos, line_length, pixel_size)
        case stream.getbyte(pos)
          when ChunkyPNG::FILTER_NONE;    # noop
          when ChunkyPNG::FILTER_SUB;     decode_png_str_scanline_sub(     stream, pos, prev_pos, line_length, pixel_size)
          when ChunkyPNG::FILTER_UP;      decode_png_str_scanline_up(      stream, pos, prev_pos, line_length, pixel_size)
          when ChunkyPNG::FILTER_AVERAGE; decode_png_str_scanline_average( stream, pos, prev_pos, line_length, pixel_size)
          when ChunkyPNG::FILTER_PAETH;   decode_png_str_scanline_paeth(   stream, pos, prev_pos, line_length, pixel_size)
          else raise ChunkyPNG::NotSupported, "Unknown filter type: #{stream.getbyte(pos)}!"
        end
      end

      # Decodes a scanline that wasn't encoded using filtering. This is a no-op.
      # @params (see #decode_png_str_scanline)
      # @return [nil]
      def decode_png_str_scanline_sub_none(stream, pos, prev_pos, line_length, pixel_size)
        # noop - this method shouldn't get called.
      end

      # Decodes a scanline in a pxielstream that was encoded using SUB filtering.
      # This will chnage the pixelstream to have unfiltered values.
      # @params (see #decode_png_str_scanline)
      # @return [nil]
      def decode_png_str_scanline_sub(stream, pos, prev_pos, line_length, pixel_size)
        for i in 1..line_length do
          stream.setbyte(pos + i, (stream.getbyte(pos + i) + (i > pixel_size ? stream.getbyte(pos + i - pixel_size) : 0)) & 0xff)
        end
      end

      # Decodes a scanline in a pxielstream that was encoded using UP filtering.
      # This will chnage the pixelstream to have unfiltered values.
      # @params (see #decode_png_str_scanline)
      # @return [nil]
      def decode_png_str_scanline_up(stream, pos, prev_pos, line_length, pixel_size)
        for i in 1..line_length do
          up = prev_pos ? stream.getbyte(prev_pos + i) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) + up) & 0xff)
        end
      end

      # Decodes a scanline in a pxielstream that was encoded using AVERAGE filtering.
      # This will chnage the pixelstream to have unfiltered values.
      # @params (see #decode_png_str_scanline)
      # @return [nil]
      def decode_png_str_scanline_average(stream, pos, prev_pos, line_length, pixel_size)
        for i in 1..line_length do
          a = (i > pixel_size) ? stream.getbyte(pos + i - pixel_size) : 0
          b = prev_pos ? stream.getbyte(prev_pos + i) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) + ((a + b) >> 1)) & 0xff)
        end
      end

      # Decodes a scanline in a pxielstream that was encoded using PAETH filtering.
      # This will chnage the pixelstream to have unfiltered values.
      # @params (see #decode_png_str_scanline)
      # @return [nil]
      def decode_png_str_scanline_paeth(stream, pos, prev_pos, line_length, pixel_size)
        for i in 1..line_length do
          cur_pos = pos + i
          a = (i > pixel_size) ? stream.getbyte(cur_pos - pixel_size) : 0
          b = prev_pos ? stream.getbyte(prev_pos + i) : 0
          c = (prev_pos && i > pixel_size) ? stream.getbyte(prev_pos + i - pixel_size) : 0
          p = a + b - c
          pa = (p - a).abs
          pb = (p - b).abs
          pc = (p - c).abs
          pr = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c)
          stream.setbyte(cur_pos, (stream.getbyte(cur_pos) + pr) & 0xff)
        end
      end
    end
  end
end
