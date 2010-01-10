module ChunkyPNG
  class Chunk
    
    def self.read(io)

      length, type = io.read(8).unpack('Na4')
      content      = io.read(length)
      crc          = io.read(4).unpack('N').first
      
      # verify_crc!(type, content, crc)
      
      CHUNK_TYPES.fetch(type, Generic).read(type, content)
    end
    
    class Base
      attr_accessor :type
      
      def initialize(type, attributes = {})
        self.type = type
        attributes.each { |k, v| send("#{k}=", v) }
      end
      
      def write_with_crc(io, content)
        message = type + content
        io << [content.length].pack('N') << message << [Zlib.crc32(message)].pack('N')
      end
      
      def write(io)
        write_with_crc(io, content || '')
      end      
    end
    
    class Generic < Base
      
      attr_accessor :content
      
      def initialize(type, content = '')
        super(type, :content => content)
      end
      
      def self.read(type, content)
        self.new(type, content)
      end
    end
    
    class Header < Base
      
      COLOR_GRAYSCALE       = 0
      COLOR_TRUECOLOR       = 2
      COLOR_INDEXED         = 3
      COLOR_GRAYSCALE_ALPHA = 4
      COLOR_TRUECOLOR_ALPHA = 6
      
      attr_accessor :width, :height, :depth, :color, :compression, :filtering, :interlace
      
      def initialize(attrs = {})
        super('IHDR', attrs)
        @depth       ||= 8
        @color       ||= COLOR_TRUECOLOR
        @compression ||= 0
        @filtering   ||= 0
        @interlace   ||= 0
      end
      
      def self.read(type, content)
        fields = content.unpack('NNC5')
        self.new(:width => fields[0],  :height => fields[1], :depth => fields[2], :color => fields[3],
                       :compression => fields[4], :filtering => fields[5], :interlace => fields[6])
      end

      def content
        [width, height, depth, color, compression, filtering, interlace].pack('NNC5')
      end
    end
    
    class End < Base
      def initialize
        super('IEND')
      end
      
      def self.read(type, content)
        raise 'The IEND chunk should be empty!' if content != ''
        self.new
      end
      
      def content
        ''
      end
    end

    class ImageData < Generic
    end
    
    # Maps chunk types to classes.
    # If a chunk type is not given in this hash, a generic chunk type will be used.
    CHUNK_TYPES = {
      'IHDR' => Header, 'IEND' => End, 'IDAT' => ImageData
    }
    
  end
end
