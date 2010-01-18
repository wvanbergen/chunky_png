module ChunkyPNG
  class Canvas
    
    # Methods for encoding a Canvas into a PNG datastream
    #
    module PNGEncoding

      attr_accessor :encoding_palette

      def write(io, constraints = {})
        to_datastream(constraints).write(io)
      end

      def save(filename, constraints = {})
        File.open(filename, 'wb') { |io| write(io, constraints) }
      end
      
      def to_blob(constraints = {})
        to_datastream(constraints).to_blob
      end
      
      alias :to_string :to_blob
      alias :to_s :to_blob

      # Converts this Canvas to a datastream, so that it can be saved as a PNG image.
      # @param [Hash] constraints The constraints to use when encoding the canvas.
      def to_datastream(constraints = {})
        data = encode_png(constraints)
        ds = Datastream.new
        ds.header_chunk       = Chunk::Header.new(data[:header])
        ds.palette_chunk      = data[:palette_chunk]      if data[:palette_chunk]
        ds.transparency_chunk = data[:transparency_chunk] if data[:transparency_chunk]
        ds.data_chunks        = Chunk::ImageData.split_in_chunks(data[:pixelstream])
        ds.end_chunk          = Chunk::End.new
        return ds
      end

      protected
      
      def encode_png(constraints = {})
        encoding = determine_png_encoding(constraints)
        result = {}
        result[:header] = { :width => width, :height => height, :color => encoding[:color_mode], :interlace => encoding[:interlace] }

        if encoding[:color_mode] == ChunkyPNG::COLOR_INDEXED
          result[:palette_chunk]      = encoding_palette.to_plte_chunk
          result[:transparency_chunk] = encoding_palette.to_trns_chunk unless encoding_palette.opaque?
        end

        result[:pixelstream] = encode_png_pixelstream(encoding[:color_mode], encoding[:interlace])
        return result
      end

      def determine_png_encoding(constraints = {})
        
        if constraints == :fast_rgb
          encoding = { :color_mode => ChunkyPNG::COLOR_TRUECOLOR }
        elsif constraints == :fast_rgba
          encoding = { :color_mode => ChunkyPNG::COLOR_TRUECOLOR_ALPHA }
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
        
        encoding[:interlace] = case encoding[:interlace]
          when nil, false, ChunkyPNG::INTERLACING_NONE then ChunkyPNG::INTERLACING_NONE
          when true, ChunkyPNG::INTERLACING_ADAM7      then ChunkyPNG::INTERLACING_ADAM7
          else encoding[:interlace]
        end

        return encoding
      end
      
      def encode_png_pixelstream(color_mode = ChunkyPNG::COLOR_TRUECOLOR, interlace = ChunkyPNG::INTERLACING_NONE)

        if color_mode == ChunkyPNG::COLOR_INDEXED && (encoding_palette.nil? || !encoding_palette.can_encode?)
          raise "This palette is not suitable for encoding!"
        end

        case interlace
          when ChunkyPNG::INTERLACING_NONE  then encode_png_image_without_interlacing(color_mode)
          when ChunkyPNG::INTERLACING_ADAM7 then encode_png_image_with_interlacing(color_mode)
          else raise "Unknown interlacing method!"
        end
      end

      def encode_png_image_without_interlacing(color_mode)
        stream = ""
        encode_png_image_pass_to_stream(stream, color_mode)
        stream
      end
      
      def encode_png_image_with_interlacing(color_mode)
        stream = ""
        0.upto(6) do |pass|
          subcanvas = self.class.adam7_extract_pass(pass, self)
          subcanvas.encoding_palette = encoding_palette
          subcanvas.encode_png_image_pass_to_stream(stream, color_mode)
        end
        stream
      end
      
      def encode_png_image_pass_to_stream(stream, color_mode)

        case color_mode
          when ChunkyPNG::COLOR_TRUECOLOR_ALPHA
            stream << pixels.pack("xN#{width}" * height)
            
          when ChunkyPNG::COLOR_TRUECOLOR 
            line_packer = 'x' + ('NX' * width)
            stream << pixels.pack(line_packer * height)
            
          else
            
            pixel_size = Color.bytesize(color_mode)
            pixel_encoder = case color_mode
              when ChunkyPNG::COLOR_TRUECOLOR       then lambda { |color| Color.to_truecolor_bytes(color) }
              when ChunkyPNG::COLOR_TRUECOLOR_ALPHA then lambda { |color| Color.to_truecolor_alpha_bytes(color) }
              when ChunkyPNG::COLOR_INDEXED         then lambda { |color| [encoding_palette.index(color)] }
              when ChunkyPNG::COLOR_GRAYSCALE       then lambda { |color| Color.to_grayscale_bytes(color) }
              when ChunkyPNG::COLOR_GRAYSCALE_ALPHA then lambda { |color| Color.to_grayscale_alpha_bytes(color) }
              else raise "Cannot encode pixels for this mode: #{color_mode}!"
            end

            previous_bytes = Array.new(pixel_size * width, 0)
            each_scanline do |line|
              unencoded_bytes = line.map(&pixel_encoder).flatten
              stream << encode_png_scanline_up(unencoded_bytes, previous_bytes, pixel_size).pack('C*')
              previous_bytes = unencoded_bytes
            end
          end
      end

      # Passes to this canvas of pixel values line by line.
      # @yield [line] Yields the scanlines of this image one by one.
      # @yieldparam [Array<Fixnum>] line An line of fixnums representing pixels
      def each_scanline(&block)
        for line_no in 0...height do
          scanline = pixels[width * line_no, width]
          yield(scanline)
        end
      end

      def encode_png_scanline(filter, bytes, previous_bytes = nil, pixelsize = 3)
        case filter
        when ChunkyPNG::FILTER_NONE    then encode_png_scanline_none(    bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_SUB     then encode_png_scanline_sub(     bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_UP      then encode_png_scanline_up(      bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_AVERAGE then encode_png_scanline_average( bytes, previous_bytes, pixelsize)
        when ChunkyPNG::FILTER_PAETH   then encode_png_scanline_paeth(   bytes, previous_bytes, pixelsize)
        else raise "Unknown filter type"
        end
      end

      def encode_png_scanline_none(original_bytes, previous_bytes = nil, pixelsize = 3)
        [ChunkyPNG::FILTER_NONE] + original_bytes
      end

      def encode_png_scanline_sub(original_bytes, previous_bytes = nil, pixelsize = 3)
        encoded_bytes = []
        for index in 0...original_bytes.length do
          a = (index >= pixelsize) ? original_bytes[index - pixelsize] : 0
          encoded_bytes[index] = (original_bytes[index] - a) % 256
        end
        [ChunkyPNG::FILTER_SUB] + encoded_bytes
      end

      def encode_png_scanline_up(original_bytes, previous_bytes, pixelsize = 3)
        encoded_bytes = []
        for index in 0...original_bytes.length do
          b = previous_bytes[index]
          encoded_bytes[index] = (original_bytes[index] - b) % 256
        end
        [ChunkyPNG::FILTER_UP] + encoded_bytes
      end
      
      def encode_png_scanline_average(original_bytes, previous_bytes, pixelsize = 3)
        encoded_bytes = []
        for index in 0...original_bytes.length do
          a = (index >= pixelsize) ? original_bytes[index - pixelsize] : 0
          b = previous_bytes[index]
          encoded_bytes[index] = (original_bytes[index] - ((a + b) >> 1)) % 256
        end
        [ChunkyPNG::FILTER_AVERAGE] + encoded_bytes
      end
      
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
          encoded_bytes[i] = (original_bytes[i] - pr) % 256
        end
        [ChunkyPNG::FILTER_PAETH] + encoded_bytes
      end
    end
  end
end
