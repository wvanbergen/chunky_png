module ChunkyPNG
  
  class Datastream
    
    SIGNATURE = [137, 80, 78, 71, 13, 10, 26, 10].pack('C8')
    
    attr_accessor :chunks

    def self.read(io)
      verify_signature!(io)

      datastream = self.new
      datastream.chunks << ChunkyPNG::Chunk.read(io) until io.eof? # until Chunk::IEND?
      return datastream
    end

    def self.verify_signature!(io)
      signature = io.read(ChunkyPNG::Datastream::SIGNATURE.length)
      raise "PNG signature not found!" unless signature == ChunkyPNG::Datastream::SIGNATURE
    end
    
    def initialize
      @chunks = []
    end
    
    def header
      chunks.first
    end
    
    def write(io)
      io << SIGNATURE
      chunks.each { |c| c.write(io) }
    end
    
    def pixel_matrix
      @pixel_matrix ||= begin
        data = ""
        chunks.each { |c| data << c.content if c.type == 'IDAT' }
        streamdata = Zlib::Inflate.inflate(data)
        matrix     = ChunkyPNG::PixelMatrix.load(header, streamdata)
      end
    end
  end
end
