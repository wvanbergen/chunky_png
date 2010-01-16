module ChunkyPNG
  
  # A PNG datastream consists of multiple chunks. This module, and the classes
  # contained within, help with handling these chunks. It supports both
  # reading and writing chunks.
  #
  # All chunck types are instances of the {ChunkyPNG::Chunk::Base} class. For
  # some chunk types a specialized class is available, e.g. the IHDR chunk is
  # represented by the {ChunkyPNG::Chunk::Header} class. These specialized
  # classes help accessing the content of the chunk. All other chunks are
  # represented by the {ChunkyPNG::Chunk::Generic} class.
  module Chunk

    # Reads a chunk from an IO stream.
    #
    # @param [IO, #read] io The IO stream to read from.
    # @return [ChunkyPNG::Chung::Base] The loaded chunk instance.
    def self.read(io)

      length, type = io.read(8).unpack('Na4')
      content      = io.read(length)
      crc          = io.read(4).unpack('N').first

      verify_crc!(type, content, crc)

      CHUNK_TYPES.fetch(type, Generic).read(type, content)
    end
    
    # Verifies the CRC of a chunk.
    # @param [String] type The chunk's type.
    # @param [String] content The chunk's content.
    # @param [Fixnum] content The chunk's content.
    # @raise [RuntimeError] An exception is raised if the found CRC value
    #    is not equal to the expected CRC value.
    def self.verify_crc!(type, content, found_crc)
      expected_crc = Zlib.crc32(content, Zlib.crc32(type))
      raise "Chuck CRC mismatch!" if found_crc != expected_crc
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

    class Text < Base

      attr_accessor :keyword, :value

      def initialize(keyword, value)
        super('tEXt')
        @keyword, @value = keyword, value
      end

      def self.read(type, content)
        keyword, value = content.unpack('Z*a*')
        new(keyword, value)
      end

      def content
        [keyword, value].pack('Z*a*')
      end
    end

    class CompressedText < Base

      attr_accessor :keyword, :value

      def initialize(keyword, value)
        super('tEXt')
        @keyword, @value = keyword, value
      end

      def self.read(type, content)
        keyword, compression, value = content.unpack('Z*Ca*')
        raise "Compression method #{compression.inspect} not supported!" unless compression == ChunkyPNG::COMPRESSION_DEFAULT
        new(keyword, Zlib::Inflate.inflate(value))
      end

      def content
        [keyword, ChunkyPNG::COMPRESSION_DEFAULT, Zlib::Deflate.deflate(value)].pack('Z*Ca*')
      end
    end

    class InternationalText < Generic
      # TODO
    end

    # Maps chunk types to classes.
    # If a chunk type is not given in this hash, a generic chunk type will be used.
    CHUNK_TYPES = {
      'IHDR' => Header, 'IEND' => End, 'IDAT' => ImageData, 'PLTE' => Palette, 'tRNS' => Transparency,
      'tEXt' => Text, 'zTXt' => CompressedText, 'iTXt' => InternationalText
    }
  end
end
