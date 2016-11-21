module ChunkyPNG
  class Frame < Canvas
    # @return [Integer] The sequence number of this frame
    attr_accessor :sequence_number

    # @return [Integer] The number of columns in this frame
    attr_accessor :width

    # @return [Integer] The number of rows in this frame
    attr_accessor :height

    # @return [Integer] X position at which to render this frame
    attr_accessor :x_offset

    # @return [Integer] Y position at which to render this frame
    attr_accessor :y_offset

    # @return [Integer] Frame delay fraction numerator
    attr_accessor :delay_num

    # @return [Integer] Frame delay fraction denominator
    attr_accessor :delay_den

    # @return [Integer] Type of frame area disposal to be done after rendering
    #   this frame
    attr_accessor :dispose_op

    # @return [Integer] Type of frame area rendering for this frame
    attr_accessor :blend_op

    # Initializes a new Frame instance by using a canvas instance.
    # @param [ChunkyPNG::Canvas] canvas The canvas to convert to frame.
    # @return [ChunkyPNG::Frame] The newly constructed frame instance.
    def self.from_canvas(canvas, attrs = {})
      new(canvas.width, canvas.height, canvas.pixels.dup, attrs)
    end

    # Decodes a Frame from a PNG encoded file.
    # @param [String] filename The file to read from.
    # @return [ChunkyPNG::Frame] The frame decoded from the PNG file.
    def self.from_file(file, attrs = {})
      from_canvas(ChunkyPNG::Canvas.from_file(file), attrs)
    end

    # Decodes the Frame from a PNG datastream instance.
    # @param [ChunkyPNG::Datastream] ds The datastream to decode.
    # @return [ChunkyPNG::Frame] The frame decoded from the PNG datastream.
    def self.from_datastream(ds, attrs = {})
      from_canvas(super(ds), attrs)
    end

    # Builds a Frame instance from a fcTL chunk and fdAT chunk from a PNG
    # datastream.
    # @param fctl_chunk [ChunkyPNG::Chunk::FrameControl]
    # @param fdat_chunks [Array<ChunkyPNG::Chunk::FrameData>]
    # @return [ChunkyPNG::Frame] The loaded Frame instance.
    def self.from_chunks(fctl_chunk, fdat_chunks, ads)
      color_mode = ads.header_chunk.color
      depth      = ads.header_chunk.depth
      interlace  = ads.header_chunk.interlace
      decoding_palette, transparent_color = nil, nil

      if fdat_chunks.any?
        case color_mode
        when ChunkyPNG::COLOR_INDEXED
          decoding_palette = ChunkyPNG::Palette.from_chunks(ads.palette_chunk,
                                                            ads.transparency_chunk)
        when ChunkyPNG::COLOR_TRUECOLOR
          transparent_color = ads.transparency_chunk.truecolor_entry(depth) if ads.transparency_chunk
        when ChunkyPNG::COLOR_GRAYSCALE
          transparent_color = ads.transparency_chunk.grayscale_entry(depth) if ads.transparency_chunk
        end

        imagedata = Chunk::FrameData.combine_chunks(fdat_chunks)
        frame = decode_png_pixelstream(imagedata, fctl_chunk.width, fctl_chunk.height,
                                       color_mode, depth, interlace,
                                       decoding_palette, transparent_color)
      else
        frame = ChunkyPNG::Frame.new(fctl_chunk.width, fctl_chunk.height)
      end

      [:x_offset, :y_offset, :delay_num, :delay_den, :dispose_op, :blend_op].each do |attr|
        frame.send("#{attr}=", fctl_chunk.send(attr))
      end
      frame
    end

    # Initializes a new Frame instance.
    # @param [Integer] width The width in pixels of this frame
    # @param [Integer] height The height in pixels of this frame
    # @param [Integer, Array<Integer>, ...] initial The initial background or
    #   the initial pixel values. (see also: {ChunkyPNG::Canvas#initialize})
    # @param [Hash] attrs specification for rendering the frame
    # @option attrs [Integer] :x_offset X position at which to render the frame.
    # @option attrs [Integer] :y_offset Y position at which to render the frame.
    # @option attrs [Integer] :delay_num Frame delay fraction numerator.
    # @option attrs [Integer] :delay_den Frame delay fraction denominator.
    # @option attrs [Integer] :dispose_op Type of frame area disposal to be done
    #   after rendering the frame.
    # @option attrs [Integer] :blend_op Type of frame area rendering for the
    #   frame.
    def initialize(width, height, initial = ChunkyPNG::Color::TRANSPARENT, attrs = {})
      super(width, height, initial)
      attrs.each { |k, v| send("#{k}=", v) }
    end

    # Returns fcTL/fdAT chunks which converted from Frame instance.
    # @return [Array<ChunkyPNG::Chunk::Base>]
    def to_chunks(seq_num = nil, constraints = {})
      [to_frame_control_chunk(seq_num), *to_frame_data_chunk(constraints)]
    end

    # Returns fcTL chunks which converted from Frame instance.
    # @return [ChunkyPNG::Chunk::FrameControl]
    def to_frame_control_chunk(seq_num = nil)
      @sequence_number = seq_num if seq_num
      ChunkyPNG::Chunk::FrameControl.new(
        :sequence_number => @sequence_number,
        :width           => @width,
        :height          => @height,
        :x_offset        => @x_offset,
        :y_offset        => @y_offset,
        :delay_num       => @delay_num,
        :delay_den       => @delay_den,
        :dispose_op      => @dispose_op,
        :blend_op        => @blend_op
      )
    end

    # @return [Array<ChunkyPNG::Chunk::FrameData>]
    # @see ChunkyPNG::Canvas::PNGEncoding#determine_png_encoding
    def to_frame_data_chunk(constraints = {})
      encoding = determine_png_encoding(constraints)
      data = encode_png_pixelstream(encoding[:color_mode], encoding[:bit_depth],
                                    encoding[:interlace],  encoding[:filtering])
      data_chunks = Chunk::ImageData.split_in_chunks(data, encoding[:compression])
      data_chunks.map.with_index do |data_chunk, idx|
        attrs = { frame_data: data_chunk.content }
        attrs[:sequence_number] = @sequence_number + idx + 1 if @sequence_number
        ChunkyPNG::Chunk::FrameData.new(attrs)
      end
    end
  end
end
