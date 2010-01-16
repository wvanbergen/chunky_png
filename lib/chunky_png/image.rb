module ChunkyPNG

  # Image class
  #
  class Image < Canvas

    METADATA_COMPRESSION_TRESHOLD = 300
    
    attr_accessor :metadata
    
    def initialize(width, height, initial = ChunkyPNG::Color::TRANSPARENT, metadata = {})
      super(width, height, initial)
      @metadata = metadata
      @metadata_compression_treshhold = 300
    end
    
    def initialize_copy(other)
      super(other)
      @metdata = other.metadata
    end
    
    def metadata_chunks
      metadata.map do |key, value|
        if value.length >= METADATA_COMPRESSION_TRESHOLD
          ChunkyPNG::Chunk::CompressedText.new(key, value)
        else
          ChunkyPNG::Chunk::Text.new(key, value)
        end
      end
    end
    
    def to_datastream(constraints = {})
      ds = super(constraints)
      ds.other_chunks += metadata_chunks
      return ds
    end
    
    def self.from_datastream(ds)
      image = super(ds)
      image.metadata = ds.metadata
      return image
    end
  end
end
