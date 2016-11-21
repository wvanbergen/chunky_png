module ChunkyPNG
  class AnimationDatastream < Datastream
    # The chunk containing the information of the animation.
    # @return [ChunkyPNG::Chunk::AnimationControl]
    attr_accessor :animation_control_chunk

    # All fcTL chunks in this Animated PNG file.
    # @return [Array<ChunkyPNG::Chunk::FrameControl>]
    attr_accessor :frame_control_chunks

    # All fdAT chunks in this Animated PNG file.
    # @return [Array<ChunkyPNG::Chunk::FrameData>]
    attr_accessor :frame_data_chunks

    class << self
      # Reads an Animated PNG datastream from an input stream
      # @param [IO] io The stream to read from.
      # @return [ChunkyPNG::AnimationDatastream] The loaded datastream instance.
      def from_io(io)
        ads = super
        ads.other_chunks.each do |chunk|
          case chunk
          when ChunkyPNG::Chunk::AnimationControl; ads.animation_control_chunk = chunk
          when ChunkyPNG::Chunk::FrameData; ads.frame_data_chunks << chunk
          when ChunkyPNG::Chunk::FrameControl; ads.frame_control_chunks << chunk
          end
        end
        ads.other_chunks = ads.other_chunks - ([ads.animation_control_chunk] +
                                               ads.frame_control_chunks +
                                               ads.frame_data_chunks)
        return ads
      end
    end

    # Initializes a new AnimationDatastream instance.
    def initialize
      super
      @frame_control_chunks = []
      @frame_data_chunks = []
    end

    # Enumerates the chunks in this datastream.
    # @see ChunkyPNG::Datastream#each_chunk
    def each_chunk
      yield(header_chunk)
      other_chunks.each { |chunk| yield(chunk) }
      yield(palette_chunk)      if palette_chunk
      yield(transparency_chunk) if transparency_chunk
      yield(physical_chunk)     if physical_chunk
      sorted_data_chunks.each  { |chunk| yield(chunk) }
      yield(end_chunk)
    end

    # Returns an array of acTL/IDAT/fcTL/fdAT chunks in the order they should
    # appear in the PNG file.
    # @return [Array<ChunkyPNG::Chunk::Base>] array of acTL/IDAT/fcTL/fdAT chunks
    def sorted_data_chunks
      res = [@animation_control_chunk]
      first_fctl = @frame_control_chunks.sort_by(&:sequence_number).first
      res << first_fctl if default_image_is_first_frame?
      res << @data_chunks
      res << sorted_animation_chunks - (res.include?(first_fctl) ? [first_fctl] : [])
      res.flatten.compact
    end

    # Returns an array of fcTL/fdAT chunks.
    # @return [Array<ChunkyPNG::Chunk::Base>] array of fcTL/fdAT chunks
    def animation_chunks
      @frame_control_chunks + @frame_data_chunks
    end

    # Returns an array of fcTL/fdAT chunks in order of sequence number.
    # @return [Array<ChunkyPNG::Chunk::Base>] array of fcTL/fdAT chunks
    def sorted_animation_chunks
      animation_chunks.sort_by(&:sequence_number)
    end

    # Returns whether default image (contents of IDAT chunk) is first frame
    # data.
    # @return [Boolean]
    def default_image_is_first_frame?
      return false if @frame_control_chunks.empty?
      # When default image is first frame, chunk structure will be as below:
      #
      #   IHDR
      #   acTL
      #   fcTL (sequence number: 1)
      #   IDAT (default image)
      #   fcTL (sequence number: 2)
      #   fdAT (sequence number: 3)
      #   ...
      #   IEND
      #
      # if default image is *not* first frame, chunk structure will be as below:
      #
      #   IHDR
      #   acTL
      #   IDAT (default image)
      #   fcTL (sequence number: 1)
      #   fdAT (sequence number: 2)
      #   fcTL (sequence number: 3)
      #   ...
      #   IEND
      #
      # in this case, difference of first fcTL chunk's sequence number to second
      # one is bigger than 1.
      first_fctl, second_fctl = @frame_control_chunks.sort_by(&:sequence_number)[0..1]
      (second_fctl.sequence_number - first_fctl.sequence_number) == 1
    end

    # Returns all fdAT chunks to which the argument (fcTL chunk) is applied.
    # @return [Array<ChunkyPNG::Chunk::FrameData>] array of fdAT chunks
    def slice_frame_data_chunks(fctl_chunk)
      min_seq_num = fctl_chunk.sequence_number
      res = []
      sorted_animation_chunks.each do |c|
        if c.sequence_number > min_seq_num
          break if c.is_a?(Chunk::FrameControl)
          res << c
        end
      end
      res
    end
  end
end
