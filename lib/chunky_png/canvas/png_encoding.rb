module ChunkyPNG
  class Canvas
    
    # Methods for encoding a Canvas instance into a PNG datastream.
    #
    # Overview of the encoding process:
    #
    # * The image is split up in scanlines (i.e. rows of pixels);
    # * All pixels are encoded as a pixelstream, based on the color mode.
    # * All the pixel bytes in the pixelstream are adjusted using a filtering 
    #   method if one is specified.
    # * Compress the resulting string using deflate compression.
    # * Split compressed data over one or more PNG chunks.
    # * These chunks should be embedded in a datastream with at least a IHDR and 
    #   IEND chunk and possibly a PLTE chunk.
    #
    # For interlaced images, the initial image is first split into 7 subimages.
    # These images get encoded exectly as above, and the result gets combined 
    # before the compression step.
    #
    # @see ChunkyPNG::Canvas::PNGDecoding
    # @see http://www.w3.org/TR/PNG/ The W3C PNG format specification
    module PNGEncoding

      # The palette used for encoding the image.This is only in used for images
      # that get encoded using indexed colors.
      # @return [ChunkyPNG::Palette]
      attr_accessor :encoding_palette

      # Writes the canvas to an IO stream, encoded as a PNG image.
      # @param [IO] io The output stream to write to.
      # @param constraints (see ChunkyPNG::Canvas::PNGEncoding#to_datastream)
      def write(io, constraints = {})
        to_datastream(constraints).write(io)
      end

      # Writes the canvas to a file, encoded as a PNG image.
      # @param [String] filname The file to save the PNG image to.
      # @param constraints (see ChunkyPNG::Canvas::PNGEncoding#to_datastream)
      def save(filename, constraints = {})
        File.open(filename, 'wb') { |io| write(io, constraints) }
      end
      
      # Encoded the canvas to a PNG formatted string.
      # @param constraints (see ChunkyPNG::Canvas::PNGEncoding#to_datastream)
      # @return [String] The PNG encoded canvas as string.
      def to_blob(constraints = {})
        to_datastream(constraints).to_blob
      end
      
      alias_method :to_string, :to_blob
      alias_method :to_s, :to_blob

      # Converts this Canvas to a datastream, so that it can be saved as a PNG image.
      # @param [Hash, Symbol] constraints The constraints to use when encoding the canvas.
      #    This can either be a hash with different constraints, or a symbol which acts as a 
      #    preset for some constraints. If no constraints are given, ChunkyPNG will decide  
      #    for itself how to best create the PNG datastream. 
      #    Supported presets are <tt>:fast_rgba</tt> for quickly saving images with transparency,
      #    <tt>:fast_rgb</tt> for quickly saving opaque images, and <tt>:best_compression</tt> to
      #    obtain the smallest possible filesize.
      # @option constraints [Fixnum] :color_mode The color mode to use. Use one of the 
      #    ChunkyPNG::COLOR_* constants.
      # @option constraints [true, false] :interlace Whether to use interlacing.
      # @option constraints [Fixnum] :compression The compression level for Zlib. This can be a
      #    value between 0 and 9, or a Zlib constant like Zlib::BEST_COMPRESSION.
      # @return [ChunkyPNG::Datastream] The PNG datastream containing the encoded canvas.
      # @see ChunkyPNG::Canvas::PNGEncoding#determine_png_encoding
      def to_datastream(constraints = {})
        encoding = determine_png_encoding(constraints)

        ds = Datastream.new
        ds.header_chunk = Chunk::Header.new(:width => width, :height => height, 
            :color => encoding[:color_mode], :interlace => encoding[:interlace])

        if encoding[:color_mode] == ChunkyPNG::COLOR_INDEXED
          ds.palette_chunk      = encoding_palette.to_plte_chunk
          ds.transparency_chunk = encoding_palette.to_trns_chunk unless encoding_palette.opaque?
        end
        data           = encode_png_pixelstream(encoding[:color_mode], encoding[:interlace], encoding[:filtering])
        ds.data_chunks = Chunk::ImageData.split_in_chunks(data, encoding[:compression])
        ds.end_chunk   = Chunk::End.new
        return ds
      end

      protected

      # Determines the best possible PNG encoding variables for this image, by analyzing 
      # the colors used for the image.
      #
      # You can provide constraints for the encoding variables by passing a hash with 
      # encoding variables to this method.
      #
      # @param [Hash, Symbol] constraints The constraints for the encoding. This can be a
      #    Hash or a preset symbol.
      # @return [Hash] A hash with encoding options for {ChunkyPNG::Canvas::PNGEncoding#to_datastream}
      def determine_png_encoding(constraints = {})

        if constraints == :fast_rgb
          encoding = { :color_mode => ChunkyPNG::COLOR_TRUECOLOR, :compression => Zlib::BEST_SPEED }
        elsif constraints == :fast_rgba
          encoding = { :color_mode => ChunkyPNG::COLOR_TRUECOLOR_ALPHA, :compression => Zlib::BEST_SPEED }
        elsif constraints == :best_compression
          encoding = { :compression => Zlib::BEST_COMPRESSION, :filtering => ChunkyPNG::FILTER_PAETH }
        elsif constraints == :good_compression
          encoding = { :compression => Zlib::BEST_COMPRESSION, :filtering => ChunkyPNG::FILTER_NONE }
        elsif constraints == :no_compression
          encoding = { :compression => Zlib::NO_COMPRESSION }
        else
          encoding = constraints
        end

        # Do not create a pallete when the encoding is given and does not require a palette.
        if encoding[:color_mode]
          if encoding[:color_mode] == ChunkyPNG::COLOR_INDEXED
            self.encoding_palette = self.palette 
          end
        else
          self.encoding_palette = self.palette
          encoding[:color_mode] ||= encoding_palette.best_colormode
        end

        # Use Zlib's default for compression unless otherwise provided.
        encoding[:compression] ||= Zlib::DEFAULT_COMPRESSION

        encoding[:interlace] = case encoding[:interlace]
          when nil, false, ChunkyPNG::INTERLACING_NONE; ChunkyPNG::INTERLACING_NONE
          when true, ChunkyPNG::INTERLACING_ADAM7;      ChunkyPNG::INTERLACING_ADAM7
          else encoding[:interlace]
        end

        encoding[:filtering] ||= case encoding[:compression]
          when Zlib::BEST_COMPRESSION; ChunkyPNG::FILTER_PAETH
          when Zlib::NO_COMPRESSION..Zlib::BEST_SPEED; ChunkyPNG::FILTER_NONE
          else ChunkyPNG::FILTER_UP
        end
        return encoding
      end
      
      # Encodes the canvas according to the PNG format specification with a given color 
      # mode, possibly with interlacing.
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] interlace The interlacing method to use.
      # @return [String] The PNG encoded canvas as string.
      def encode_png_pixelstream(color_mode = ChunkyPNG::COLOR_TRUECOLOR, interlace = ChunkyPNG::INTERLACING_NONE, filtering = ChunkyPNG::FILTER_NONE)

        if color_mode == ChunkyPNG::COLOR_INDEXED && (encoding_palette.nil? || !encoding_palette.can_encode?)
          raise ChunkyPNG::ExpectationFailed, "This palette is not suitable for encoding!"
        end

        case interlace
          when ChunkyPNG::INTERLACING_NONE;  encode_png_image_without_interlacing(color_mode, filtering)
          when ChunkyPNG::INTERLACING_ADAM7; encode_png_image_with_interlacing(color_mode, filtering)
          else raise ChunkyPNG::NotSupported, "Unknown interlacing method: #{interlace}!"
        end
      end

      # Encodes the canvas according to the PNG format specification with a given color mode.
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] filtering The filtering method to use.
      # @return [String] The PNG encoded canvas as string.
      def encode_png_image_without_interlacing(color_mode, filtering = ChunkyPNG::FILTER_NONE)
        stream = ChunkyPNG::Datastream.empty_bytearray
        encode_png_image_pass_to_stream(stream, color_mode, filtering)
        stream
      end

      # Encodes the canvas according to the PNG format specification with a given color 
      # mode and Adam7 interlacing.
      #
      # This method will split the original canva in 7 smaller canvases and encode them 
      # one by one, concatenating the resulting strings.
      #
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] filtering The filtering method to use.
      # @return [String] The PNG encoded canvas as string.
      def encode_png_image_with_interlacing(color_mode, filtering = ChunkyPNG::FILTER_NONE)
        stream = ChunkyPNG::Datastream.empty_bytearray
        0.upto(6) do |pass|
          subcanvas = self.class.adam7_extract_pass(pass, self)
          subcanvas.encoding_palette = encoding_palette
          subcanvas.encode_png_image_pass_to_stream(stream, color_mode, filtering)
        end
        stream
      end

      # Encodes the canvas to a stream, in a given color mode.
      # @param [String] stream The stream to write to.
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] filtering The filtering method to use.
      def encode_png_image_pass_to_stream(stream, color_mode, filtering)

        start_pos  = stream.bytesize
        pixel_size = Color.pixel_bytesize(color_mode)
        line_width = pixel_size * width
        
        # Encode the whole image without filtering
        stream << case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR; pixels.pack(('x' + ('NX' * width)) * height)
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA; pixels.pack("xN#{width}" * height)
          when ChunkyPNG::COLOR_INDEXED; pixels.map { |p| encoding_palette.index(p) }.pack("xC#{width}" * height)
          when ChunkyPNG::COLOR_GRAYSCALE; pixels.map { |p| p >> 8 }.pack("xC#{width}" * height)
          when ChunkyPNG::COLOR_GRAYSCALE_ALPHA; pixels.pack("xn#{width}" * height)
          else raise ChunkyPNG::NotSupported, "Cannot encode pixels for this mode: #{color_mode}!"
        end
        
        # Determine the filter method
        filter_method = case filtering
          when ChunkyPNG::FILTER_SUB;     :encode_png_str_scanline_sub
          when ChunkyPNG::FILTER_UP;      :encode_png_str_scanline_up
          when ChunkyPNG::FILTER_AVERAGE; :encode_png_str_scanline_average
          when ChunkyPNG::FILTER_PAETH;   :encode_png_str_scanline_paeth
          else nil
        end
        
        # Now, apply filtering if any
        if filter_method
          (height - 1).downto(0) do |y|
            pos = start_pos + y * (line_width + 1)
            prev_pos = (y == 0) ? nil : pos - (line_width + 1)
            send(filter_method, stream, pos, prev_pos, line_width, pixel_size)
          end
        end
      end

      # Encodes a scanline of a pixelstream without filtering. This is a no-op.
      # @param [String] stream The pixelstream to work on. This string will be modified.
      # @param [Integer] pos The starting position of the scanline.
      # @param [Integer, nil] prev_pos The starting position of the previous scanline. <tt>nil</tt> if
      #     this is the first line.
      # @param [Integer] line_width The number of bytes in this scanline, without counting the filtering
      #     method byte.
      # @param [Integer] pixel_size The number of bytes used per pixel.
      # @return [nil]
      def encode_png_str_scanline_none(stream, pos, prev_pos, line_width, pixel_size)
        # noop - this method shouldn't get called at all.
      end

      # Encodes a scanline of a pixelstream using SUB filtering. This will modify the stream.
      # @param (see #encode_png_str_scanline_none)
      # @return [nil]
      def encode_png_str_scanline_sub(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          a = (i > pixel_size) ? stream.getbyte(pos + i - pixel_size) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - a) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_SUB)
      end

      # Encodes a scanline of a pixelstream using UP filtering. This will modify the stream.
      # @param (see #encode_png_str_scanline_none)
      # @return [nil]
      def encode_png_str_scanline_up(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          b = prev_pos ? stream.getbyte(prev_pos + i) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - b) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_UP)
      end
      
      # Encodes a scanline of a pixelstream using AVERAGE filtering. This will modify the stream.
      # @param (see #encode_png_str_scanline_none)
      # @return [nil]
      def encode_png_str_scanline_average(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          a = (i > pixel_size) ? stream.getbyte(pos + i - pixel_size) : 0
          b = prev_pos ? stream.getbyte(prev_pos + i) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - ((a + b) >> 1)) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_AVERAGE)
      end
      
      # Encodes a scanline of a pixelstream using PAETH filtering. This will modify the stream.
      # @param (see #encode_png_str_scanline_none)
      # @return [nil]
      def encode_png_str_scanline_paeth(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          a = (i > pixel_size) ? stream.getbyte(pos + i - pixel_size) : 0
          b = (prev_pos) ? stream.getbyte(prev_pos + i) : 0
          c = (prev_pos && i > pixel_size) ? stream.getbyte(prev_pos + i - pixel_size) : 0
          p = a + b - c
          pa = (p - a).abs
          pb = (p - b).abs
          pc = (p - c).abs
          pr = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c)
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - pr) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_PAETH)
      end      
    end
  end
end
