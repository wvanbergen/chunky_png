module ChunkyPNG

  class Datastream

    SIGNATURE = [137, 80, 78, 71, 13, 10, 26, 10].pack('C8')

    attr_accessor :header_chunk
    attr_accessor :other_chunks
    attr_accessor :palette_chunk
    attr_accessor :transparency_chunk
    attr_accessor :data_chunks
    attr_accessor :end_chunk

    def initialize
      @other_chunks = []
      @data_chunks  = []
    end
    
    #############################################
    # LOADING DATASTREAMS
    #############################################
    
    class << self

      def from_blob(str)
        from_io(StringIO.new(str))
      end
      
      alias :from_string :from_blob
    
      def from_file(filename)
        ds = nil
        File.open(filename, 'rb') { |f| ds = from_io(f) }
        ds
      end

      def from_io(io)
        verify_signature!(io)

        ds = self.new
        until io.eof?
          chunk = ChunkyPNG::Chunk.read(io)
          case chunk
            when ChunkyPNG::Chunk::Header       then ds.header_chunk        = chunk
            when ChunkyPNG::Chunk::Palette      then ds.palette_chunk       = chunk
            when ChunkyPNG::Chunk::Transparency then ds.transparency_chunk  = chunk
            when ChunkyPNG::Chunk::ImageData    then ds.data_chunks        << chunk
            when ChunkyPNG::Chunk::End          then ds.end_chunk           = chunk
            else ds.other_chunks << chunk
          end
        end
        return ds
      end

      def verify_signature!(io)
        signature = io.read(ChunkyPNG::Datastream::SIGNATURE.length)
        raise "PNG signature not found!" unless signature == ChunkyPNG::Datastream::SIGNATURE
      end
    end

    #############################################
    # CHUNKS
    #############################################
    
    def each_chunk
      yield(header_chunk)
      other_chunks.each { |chunk| yield(chunk) }
      yield(palette_chunk)      if palette_chunk
      yield(transparency_chunk) if transparency_chunk
      data_chunks.each  { |chunk| yield(chunk) }
      yield(end_chunk)
    end

    def chunks
      enum_for(:each_chunk)
    end

    #############################################
    # WRITING DATASTREAMS
    #############################################

    def write(io)
      io << SIGNATURE
      each_chunk { |c| c.write(io) }
    end
    
    def save(filename)
      File.open(filename, 'w') { |f| write(f) }
    end
    
    def to_blob
      str = StringIO.new
      write(str)
      return str.string
    end
    
    alias :to_string :to_blob
    alias :to_s :to_blob
    
  end
end
