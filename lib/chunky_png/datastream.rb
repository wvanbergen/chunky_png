module ChunkyPNG
  
  class Datastream
    
    SIGNATURE = [137, 80, 78, 71, 13, 10, 26, 10].pack('C8')
    
    attr_accessor :header_chunk
    attr_accessor :other_chunks
    attr_accessor :palette_chunk
    attr_accessor :data_chunks
    attr_accessor :end_chunk

    def self.read(io)
      verify_signature!(io)

      ds = self.new
      until io.eof?
        chunk = ChunkyPNG::Chunk.read(io)
        case chunk
          when ChunkyPNG::Chunk::Header    then ds.header_chunk  = chunk
          when ChunkyPNG::Chunk::Palette   then ds.palette_chunk = chunk
          when ChunkyPNG::Chunk::ImageData then ds.data_chunks  << chunk
          when ChunkyPNG::Chunk::End       then ds.end_chunk     = chunk
          else ds.other_chunks << chunk
        end
      end
      return ds
    end

    def self.verify_signature!(io)
      signature = io.read(ChunkyPNG::Datastream::SIGNATURE.length)
      raise "PNG signature not found!" unless signature == ChunkyPNG::Datastream::SIGNATURE
    end
    
    def chunks
      cs = [header_chunk]
      cs += other_chunks
      cs << palette_chunk if palette_chunk
      cs += data_chunks
      cs << end_chunk
      return cs
    end
    
    def initialize
      @other_chunks = []
      @data_chunks  = []
    end
    
    def write(io)
      io << SIGNATURE
      chunks.each { |c| c.write(io) }
    end
    
    def idat_chunks(data)
      streamdata = Zlib::Deflate.deflate(data)
      # TODO: Split long streamdata over multiple chunks
      return [ ChunkyPNG::Chunk::ImageData.new('IDAT', streamdata) ]
    end
    
    def pixel_matrix=(pixel_matrix)
      @pixel_matrix = pixel_matrix
    end
    
    def pixel_matrix
      @pixel_matrix ||= begin
        data = data_chunks.map(&:content).join('')
        streamdata = Zlib::Inflate.inflate(data)
        matrix     = ChunkyPNG::PixelMatrix.load(header, streamdata)
      end
    end
  end
end
