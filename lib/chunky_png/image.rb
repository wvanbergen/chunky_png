module ChunkyPNG

  # Image class
  #
  class Image < PixelMatrix
    
    attr_reader :metadata
    
    def initialize(width, height, initial = ChunkyPNG::Color::TRANSPARENT, metadata = {})
      super(width, height, initial)
      @metadata = metadata
    end
    
    def initialize_copy(other)
      super(other)
      @metdata = other.metadata
    end
    
    def to_datastream(constraints = {})
      ds = super(constraints)
      # TODO: text chunks
      return ds
    end
    
    def self.from_datastream(ds)
      image = super(ds)
      # TODO: text chunks
      return image
    end
  end
end
