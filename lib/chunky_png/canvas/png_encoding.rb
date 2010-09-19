module ChunkyPNG
  class Canvas
    
    # Methods for encoding a Canvas instance into a PNG datastream.
    #
    # Overview of the encoding process:
    #
    # * The image is split up in scanlines (i.e. rows of pixels);
    # * Every pixel in this row is converted into bytes, based on the color mode;
    # * Filter every byte in the row according to the filter method.
    # * Concatenate all the filtered bytes of every line to a single stream
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
      
      alias :to_string :to_blob
      alias :to_s :to_blob

      # Converts this Canvas to a datastream, so that it can be saved as a PNG image.
      # @param [Hash, Symbol] constraints The constraints to use when encoding the canvas.
      #    This can either be a hash with different constraints, or a symbol which acts as a 
      #    preset for some constraints. If no constraints are given, ChunkyPNG will decide  
      #    for itself how to best create the PNG datastream. 
      #    Supported presets are :fast_rgba for quickly saving images with transparency,
      #    :fast_rgb for quickly saving opaque images, and :best_compression to obtain the
      #    smallest possible filesize.
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
        
        data           = encode_png_pixelstream(encoding[:color_mode], encoding[:interlace], encoding[:compression])
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
          encoding = { :compression => Zlib::BEST_COMPRESSION }
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
        
        encoding[:compression] ||= Zlib::DEFAULT_COMPRESSION
        
        encoding[:interlace] = case encoding[:interlace]
          when nil, false, ChunkyPNG::INTERLACING_NONE then ChunkyPNG::INTERLACING_NONE
          when true, ChunkyPNG::INTERLACING_ADAM7      then ChunkyPNG::INTERLACING_ADAM7
          else encoding[:interlace]
        end

        return encoding
      end
      
      # Encodes the canvas according to the PNG format specification with a given color 
      # mode, possibly with interlacing.
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] interlace The interlacing method to use.
      # @param [Integer] compression The Zlib compression level.
      # @return [String] The PNG encoded canvas as string.
      def encode_png_pixelstream(color_mode = ChunkyPNG::COLOR_TRUECOLOR, interlace = ChunkyPNG::INTERLACING_NONE, compression = ZLib::DEFAULT_COMPRESSION)

        if color_mode == ChunkyPNG::COLOR_INDEXED && (encoding_palette.nil? || !encoding_palette.can_encode?)
          raise ChunkyPNG::ExpectationFailed, "This palette is not suitable for encoding!"
        end

        case interlace
          when ChunkyPNG::INTERLACING_NONE  then encode_png_image_without_interlacing(color_mode, compression)
          when ChunkyPNG::INTERLACING_ADAM7 then encode_png_image_with_interlacing(color_mode, compression)
          else raise ChunkyPNG::NotSupported, "Unknown interlacing method: #{interlace}!"
        end
      end

      # Encodes the canvas according to the PNG format specification with a given color mode.
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] compression The Zlib compression level.
      # @return [String] The PNG encoded canvas as string.
      def encode_png_image_without_interlacing(color_mode, compression = ZLib::DEFAULT_COMPRESSION)
        stream = ""
        encode_png_image_pass_to_stream(stream, color_mode, compression)
        stream
      end
      
      # Encodes the canvas according to the PNG format specification with a given color 
      # mode and Adam7 interlacing.
      #
      # This method will split the original canva in 7 smaller canvases and encode them 
      # one by one, concatenating the resulting strings.
      #
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] compression The Zlib compression level.
      # @return [String] The PNG encoded canvas as string.
      def encode_png_image_with_interlacing(color_mode, compression = ZLib::DEFAULT_COMPRESSION)
        stream = ""
        0.upto(6) do |pass|
          subcanvas = self.class.adam7_extract_pass(pass, self)
          subcanvas.encoding_palette = encoding_palette
          subcanvas.encode_png_image_pass_to_stream(stream, color_mode, compression)
        end
        stream
      end
      
      # Encodes the canvas to a stream, in a given color mode.
      # @param [String, IO, :<<] stream The stream to write to.
      # @param [Integer] color_mode The color mode to use for encoding.
      # @param [Integer] compression The Zlib compression level.
      def encode_png_image_pass_to_stream(stream, color_mode, compression = ZLib::DEFAULT_COMPRESSION)

        start_pos  = stream.bytesize
        pixel_size = Color.bytesize(color_mode)
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
        filter_method = case compression
          when Zlib::BEST_COMPRESSION; :encode_png_str_scanline_paeth
          when Zlib::NO_COMPRESSION..Zlib::BEST_SPEED; nil
          else :encode_png_str_scanline_up
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

      def encode_png_str_scanline_none(stream, pos, prev_pos, line_width, pixel_size)
        # noop - this method shouldn't get called at all.
      end

      def encode_png_str_scanline_sub(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          a = (i > pixel_size) ? stream.getbyte(pos + i - pixel_size) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - a) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_SUB)
      end

      def encode_png_str_scanline_up(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          b = prev_pos ? stream.getbyte(prev_pos + i) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - b) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_UP)
      end
      
      def encode_png_str_scanline_average(stream, pos, prev_pos, line_width, pixel_size)
        line_width.downto(1) do |i|
          a = (i > pixel_size) ? stream.getbyte(pos + i - pixel_size) : 0
          b = prev_pos ? stream.getbyte(prev_pos + i) : 0
          stream.setbyte(pos + i, (stream.getbyte(pos + i) - ((a + b) >> 1)) & 0xff)
        end
        stream.setbyte(pos, ChunkyPNG::FILTER_AVERAGE)
      end
      
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
      

      # Passes to this canvas of pixel values line by line.
      # @yield [line] Yields the scanlines of this image one by one.
      # @yieldparam [Array<Integer>] line An line of fixnums representing pixels
      def each_scanline(&block)
        for line_no in 0...height do
          scanline = pixels[width * line_no, width]
          yield(scanline)
        end
      end

      # Encodes the bytes of a scanline with a given filter.
      # @param [Integer] filter The filter method to use.
      # @param [Array<Integer>]  bytes The scanline bytes to encode.
      # @param [Array<Integer>]  previous_bytes The original bytes of the previous scanline.
      # @param [Integer] pixelsize The number of bytes per pixel.
      # @return [Array<Integer>] The filtered array of bytes.
      def encode_png_scanline(filter, bytes, previous_bytes = nil, pixelsize = 3)
        case filter
        when ChunkyPNG::FILTER_NONE    then encode_png_scanline_none(    bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_SUB     then encode_png_scanline_sub(     bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_UP      then encode_png_scanline_up(      bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_AVERAGE then encode_png_scanline_average( bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_PAETH   then encode_png_scanline_paeth(   bytes, previous_bytes, pixelsize)
        else raise ChunkyPNG::NotSupported, "Unknown filter type: #{filter}!"
        end
      end

      # Encodes the bytes of a scanline without filtering.
      # @param [Array<Integer>]  bytes The scanline bytes to encode.
      # @param [Array<Integer>]  previous_bytes The original bytes of the previous scanline.
      # @param [Integer] pixelsize The number of bytes per pixel.
      # @return [Array<Integer>] The filtered array of bytes.
      def encode_png_scanline_none(original_bytes, previous_bytes = nil, pixelsize = 3)
        [ChunkyPNG::FILTER_NONE] + original_bytes
      end

      # Encodes the bytes of a scanline with SUB filtering.
      # @param (see ChunkyPNG::Canvas::PNGEncoding#encode_png_scanline_none)
      def encode_png_scanline_sub(original_bytes, previous_bytes = nil, pixelsize = 3)
        encoded_bytes = []
        for index in 0...original_bytes.length do
          a = (index >= pixelsize) ? original_bytes[index - pixelsize] : 0
          encoded_bytes[index] = (original_bytes[index] - a) & 0xff
        end
        [ChunkyPNG::FILTER_SUB] + encoded_bytes
      end

      # Encodes the bytes of a scanline with UP filtering.
      # @param (see ChunkyPNG::Canvas::PNGEncoding#encode_png_scanline_none)
      def encode_png_scanline_up(original_bytes, previous_bytes, pixelsize = 3)
        encoded_bytes = []
        for index in 0...original_bytes.length do
          b = previous_bytes[index]
          encoded_bytes[index] = (original_bytes[index] - b) & 0xff
        end
        [ChunkyPNG::FILTER_UP] + encoded_bytes
      end

      # Encodes the bytes of a scanline with AVERAGE filtering.
      # @param (see ChunkyPNG::Canvas::PNGEncoding#encode_png_scanline_none)
      def encode_png_scanline_average(original_bytes, previous_bytes, pixelsize = 3)
        encoded_bytes = []
        for index in 0...original_bytes.length do
          a = (index >= pixelsize) ? original_bytes[index - pixelsize] : 0
          b = previous_bytes[index]
          encoded_bytes[index] = (original_bytes[index] - ((a + b) >> 1)) & 0xff
        end
        [ChunkyPNG::FILTER_AVERAGE] + encoded_bytes
      end

      # Encodes the bytes of a scanline with PAETH filtering.
      # @param (see ChunkyPNG::Canvas::PNGEncoding#encode_png_scanline_none)
      def encode_png_scanline_paeth(original_bytes, previous_bytes, pixelsize = 3)
        encoded_bytes = []
        for i in 0...original_bytes.length do
          a = (i >= pixelsize) ? original_bytes[i - pixelsize] : 0
          b = previous_bytes[i]
          c = (i >= pixelsize) ? previous_bytes[i - pixelsize] : 0
          p = a + b - c
          pa = (p - a).abs
          pb = (p - b).abs
          pc = (p - c).abs
          pr = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c)
          encoded_bytes[i] = (original_bytes[i] - pr) & 0xff
        end
        [ChunkyPNG::FILTER_PAETH] + encoded_bytes
      end
    end
  end
end
