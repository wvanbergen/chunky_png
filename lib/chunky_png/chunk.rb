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
        io << [content.length].pack('N') << type << content
        io << [Zlib.crc32(content, Zlib.crc32(type))].pack('N')
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

      attr_accessor :width, :height, :depth, :color, :compression, :filtering, :interlace

      def initialize(attrs = {})
        super('IHDR', attrs)
        @depth       ||= 8
        @color       ||= ChunkyPNG::COLOR_TRUECOLOR
        @compression ||= ChunkyPNG::COMPRESSION_DEFAULT
        @filtering   ||= ChunkyPNG::FILTERING_DEFAULT
        @interlace   ||= ChunkyPNG::INTERLACING_NONE
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

    class Palette < Generic
    end

    class Transparency < Generic
    end

    class ImageData < Generic
      
      def self.combine_chunks(data_chunks)
        Zlib::Inflate.inflate(data_chunks.map(&:content).join(''))
      end
      
      def self.split_in_chunks(data, chunk_size = 2147483647)
        streamdata = Zlib::Deflate.deflate(data)
        # TODO: Split long streamdata over multiple chunks
        [ ChunkyPNG::Chunk::ImageData.new('IDAT', streamdata) ]
      end
    end

    # Maps chunk types to classes.
    # If a chunk type is not given in this hash, a generic chunk type will be used.
    CHUNK_TYPES = {
      'IHDR' => Header, 'IEND' => End, 'IDAT' => ImageData, 'PLTE' => Palette, 'tRNS' => Transparency
    }
  end
end
