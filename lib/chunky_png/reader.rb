module ChunkyPNG
  
  class Reader
    
    attr_reader :io
    attr_reader :datastream
    
    def self.io
      self.new(io).datastream
    end
      
    def self.file(file)
      File.open(file, 'r') do |f|
        self.new(f).datastream
      end
    end
      
    def self.string(string)
      self.new(StringIO.new(string)).datastream
    end
    
    protected
    
    def initialize(io)
      @io = io
      verify_signature!
      
      @datastream = PNG::Datastream.new
      @datastream.chunks << PNG::Chunk.read(@io) until @io.eof?
      return @datastream
    end
    
    def verify_signature!
      signature = @io.read(PNG::Datastream::SIGNATURE.length)
      raise "PNG signature not found!" unless signature == PNG::Datastream::SIGNATURE
    end
  end
end
