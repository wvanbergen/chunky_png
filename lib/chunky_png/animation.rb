require 'chunky_png/frame'
require 'chunky_png/animation_datastream'

module ChunkyPNG
  class Animation < Canvas

    # @return [Array<ChunkyPNG::Frame>] The array of frames in this animation
    attr_accessor :frames

    # @return [Boolean] Indicates whether the content of IDAT chunk (content of
    #   {#pixels @pixels}) is the first frame for this animation
    attr_accessor :default_image_is_first_frame

    # @return [Integer] Indicates the number of times that this animation should
    #   play
    attr_accessor :num_plays

    #################################################################
    # CONSTANTS
    #################################################################

    # Indicates that the APNG image play in infinite loop.
    INFINITE_LOOP = 0

    # Indicates that no disposal is done on the frame before rendering the next.
    APNG_DISPOSE_OP_NONE = 0

    # Indicates that the frame's region of the output buffer is to be cleared to
    # fully transparent black before rendering the next frame.
    APNG_DISPOSE_OP_BACKGROUND = 1

    # Indicates that the frame's region of the output buffer is to be reverted
    # to the previous contents before rendering the next frame.
    APNG_DISPOSE_OP_PREVIOUS = 2

    # Indicates that all color components of the frame, including alpha,
    # overwrite the current contents of the frame's output buffer region.
    APNG_BLEND_OP_SOURCE = 0

    # Indicates that the frame should be composited onto the output buffer based
    # on its alpha, using a simple OVER operation.
    APNG_BLEND_OP_OVER = 1

    #################################################################
    # CONSTRUCTORS
    #################################################################

    # Initializes a new Animation instance.
    #
    # @param [Integer] width The width in pixels of this canvas
    # @param [Integer] height The height in pixels of this canvas
    # @param [Integer, Array<Integer>, ...] initial The initial background or
    #   the initial pixel values. (see also: {ChunkyPNG::Canvas#initialize})
    # @param [Boolean] first_frame if it is true, <tt>width</tt>,
    #   <tt>height</tt> and <tt>initial</tt> also used to generate the first
    #   frame.
    #
    # @see ChunkyPNG::Canvas#initialize
   def initialize(width, height, initial = ChunkyPNG::Color::TRANSPARENT, first_frame = false)
      super(width, height, initial)
      @default_image_is_first_frame = first_frame
      @frames = first_frame ? [ChunkyPNG::Frame.new(width, height, initial)] : []
    end

   # Initializes a new Animation instance by {ChunkyPNG::Frame} instance.
   # @param [ChunkyPNG::Frame] frame The first frame for this animation.
    def self.from_frame(frame)
      new(frame.width, frame.height, frame.pixels).tap do |animation|
        animation.default_image_is_first_frame = true
        animation.frames = [frame]
      end
    end

    # Returns the total number of frames in this animation.
    # @return [Integer] The total numer of frames.
    def num_frames
      @frames.size
    end

    #################################################################
    # DECODING
    #################################################################

    class << self
      # Decodes an Animation from an Animated PNG encoded string.
      # @param [String] str The string to read from.
      # @return [ChunkyPNG::Animation] The animation decoded from the Animated
      #   PNG encoded string.
      def from_blob(str)
        from_datastream(ChunkyPNG::AnimationDatastream.from_blob(str))
      end

      alias_method :from_string, :from_blob

      # Decodes an Animation from an Animated PNG encoded file.
      # @param [String] filename The file to read from.
      # @return [ChunkyPNG::Animation] The animation decoded from the Animated
      #   PNG file.
      def from_file(filename)
        from_datastream(ChunkyPNG::AnimationDatastream.from_file(filename))
      end

      # Decodes an Animation from an Animated PNG encoded stream.
      # @param [IO, #read] io The stream to read from.
      # @return [ChunkyPNG::Animation] The animation decoded from the Animated
      #   PNG stream.
      def from_io(io)
        from_datastream(ChunkyPNG::AnimationDatastream.from_io(io))
      end

      # Decodes the Animation from an Animated PNG datastream instance.
      # @param [ChunkyPNG::AnimationDatastream] ads The datastream to decode.
      # @return [ChunkyPNG::Animation] The animation decoded from the Animated
      #   PNG datastream.
      def from_datastream(ads)
        animation = super(ads)
        ads.animation_control_chunk ||= ChunkyPNG::Chunk::AnimationControl.new

        animation.default_image_is_first_frame = ads.default_image_is_first_frame?
        animation.num_plays = ads.animation_control_chunk.num_plays

        ads.frame_control_chunks.each do |fctl_chunk|
          fdat_chunks = ads.slice_frame_data_chunks(fctl_chunk)
          frame = ChunkyPNG::Frame.from_chunks(fctl_chunk, fdat_chunks, ads)
          animation.frames << frame
        end

        unless ads.animation_control_chunk.num_frames == animation.num_frames
          raise ChunkyPNG::ExpectationFailed, 'num_frames missmatched!'
        end
        animation
      end
    end

    #################################################################
    # ENCODING
    #################################################################

    # Converts this Animation to a datastream, so that it can be saved as an
    # Animated PNG image.
    # @param [Hash, Symbol] constraints The constraints to use when encoding the
    #   animation.
    # @return [ChunkyPNG::AnimationDatastream] The Animated PNG datastream.
    # @see ChunkyPNG::Canvas::PNGEncoding#to_datastream
    def to_datastream(constraints = {})
      encoding = determine_png_encoding(constraints)

      ds = AnimationDatastream.new
      ds.header_chunk = Chunk::Header.new(:width => width, :height => height,
                                          :color => encoding[:color_mode],
                                          :depth => encoding[:bit_depth],
                                          :interlace => encoding[:interlace])
      if encoding[:color_mode] == ChunkyPNG::COLOR_INDEXED
        ds.palette_chunk      = encoding_palette.to_plte_chunk
        ds.transparency_chunk = encoding_palette.to_trns_chunk unless encoding_palette.opaque?
      end

      ds.animation_control_chunk = Chunk::AnimationControl.new(:num_frames => num_frames,
                                                               :num_plays  => num_plays)

      data = encode_png_pixelstream(encoding[:color_mode], encoding[:bit_depth],
                                    encoding[:interlace], encoding[:filtering])
      ds.data_chunks = Chunk::ImageData.split_in_chunks(data, encoding[:compression])

      idx = 0
      frames.each do |frame|
        if idx == 0 && @default_image_is_first_frame
          ds.frame_control_chunks << frame.to_frame_control_chunk(0)
        else
          fctl_chunk, *fdat_chunks = *frame.to_chunks(idx, constraints)
          ds.frame_control_chunks << fctl_chunk
          ds.frame_data_chunks = ds.frame_data_chunks + fdat_chunks
        end
        idx = ds.animation_chunks.size
      end

      ds.end_chunk = Chunk::End.new
      return ds
    end
  end
end
