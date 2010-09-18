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
    # * For every line of pixels in the original image, the determined amount
    #   of bytes is read from the pixel stream.
    # * The read bytes are unfiltered given by the filter function specified by
    #   the first byte of the line.
    # * The unfiltered bytes are converted into colored pixels, using the color mode.
    # * All lines combined form the original image.
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
          when ChunkyPNG::INTERLACING_NONE  then decode_png_without_interlacing(stream, width, height, color_mode)
          when ChunkyPNG::INTERLACING_ADAM7 then decode_png_with_adam7_interlacing(stream, width, height, color_mode)
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
        
        pixel_size    = Color.bytesize(color_mode)
        pixel_decoder = case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR       then lambda { |bytes| ChunkyPNG::Color.rgb(*bytes) }
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA then lambda { |bytes| ChunkyPNG::Color.rgba(*bytes) }
          when ChunkyPNG::COLOR_INDEXED         then lambda { |bytes| decoding_palette[bytes.first] }
          when ChunkyPNG::COLOR_GRAYSCALE       then lambda { |bytes| ChunkyPNG::Color.grayscale(*bytes) }
          when ChunkyPNG::COLOR_GRAYSCALE_ALPHA then lambda { |bytes| ChunkyPNG::Color.grayscale_alpha(*bytes) }
          else raise ChunkyPNG::NotSupported, "No suitable pixel decoder found for color mode #{color_mode}!"
        end
        
        pixels = []
        if width > 0
          
          raise ChunkyPNG::ExpectationFailed, "Invalid stream length!" unless stream.length - start_pos >= width * height * pixel_size + height
          
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

      # Decodes filtered bytes from a scanline from a PNG pixelstream,
      # to return the original bytes of the image.
      #
      # The decoded bytes should be used to get the original pixels of the 
      # scanline, combining them using a color mode dependent color decoder.
      #
      # @param [Integer] filter The filter used to encode the bytes.
      # @param [Array<Integer>] bytes The filtered bytes to decode.
      # @param [Array<Integer>] previous_bytes The decoded bytes of the 
      #      previous scanline.
      # @param [Integer] pixelsize The amount of bytes used for every pixel.
      #      This depends on the used color mode and color depth.
      # @return [Array<Integer>] The array of original bytes for the scanline,
      #      before they were encoded.
      def decode_png_scanline(filter, bytes, previous_bytes, pixelsize = 3)
        case filter
        when ChunkyPNG::FILTER_NONE    then decode_png_scanline_none(    bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_SUB     then decode_png_scanline_sub(     bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_UP      then decode_png_scanline_up(      bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_AVERAGE then decode_png_scanline_average( bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_PAETH   then decode_png_scanline_paeth(   bytes, previous_bytes, pixelsize)
        else raise ChunkyPNG::NotSupported, "Unknown filter type: #{filter}!"
        end
      end

      # Decoded filtered scanline bytes that were not filtered.
      # @param bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param previous_bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param pixelsize (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline
      def decode_png_scanline_none(bytes, previous_bytes, pixelsize = 3)
        bytes
      end

      # Decoded filtered scanline bytes that were filtered using SUB filtering.
      # @param bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param previous_bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param pixelsize (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline
      def decode_png_scanline_sub(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index { |b, i| bytes[i] = (b + (i >= pixelsize ? bytes[i-pixelsize] : 0)) & 0xff }
        bytes
      end

      # Decoded filtered scanline bytes that were filtered using UP filtering.
      # @param bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param previous_bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param pixelsize (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline
      def decode_png_scanline_up(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index { |b, i| bytes[i] = (b + previous_bytes[i]) & 0xff }
        bytes
      end

      # Decoded filtered scanline bytes that were filtered using AVERAGE filtering.
      # @param bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param previous_bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param pixelsize (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline
      def decode_png_scanline_average(bytes, previous_bytes, pixelsize = 3)
        bytes.each_with_index do |byte, i|
          a = (i >= pixelsize) ? bytes[i - pixelsize] : 0
          b = previous_bytes[i]
          bytes[i] = (byte + ((a + b) >> 1)) & 0xff
        end
        bytes
      end

      # Decoded filtered scanline bytes that were filtered using PAETH filtering.
      # @param bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param previous_bytes (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @param pixelsize (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @return (see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline)
      # @see ChunkyPNG::Canvas::PNGDecoding#decode_png_scanline
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
          bytes[i] = (byte + pr) & 0xff
        end
        bytes
      end
    end
  end
end
