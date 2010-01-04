module ChunkyPNG
  
  class Datastream
    
    SIGNATURE = [137, 80, 78, 71, 13, 10, 26, 10].pack('C*8')
    
    attr_accessor :chunks
    
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
        matrix     = PNG::PixelMatrix.load(header, streamdata)
      end
    end
  end
end
