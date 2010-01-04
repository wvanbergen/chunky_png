module ChunkyPNG
  
  class PixelMatrix
    
    FILTER_NONE    = 0
    FILTER_SUB     = 1
    FILTER_UP      = 2
    FILTER_AVERAGE = 3
    FILTER_PAETH   = 4
    
    attr_accessor :pixels, :width, :height
    
    def self.load(header, content)
      matrix = self.new(header.width, header.height)
      matrix.decode_pixelstream(content, header)
      return matrix
    end
    
    def initialize(width, height, background_color = PNG::Color::Black)
      @width, @height = width, height
      @pixels = Array.new(width * height)
    end
    
    def decode_pixelstream(stream, header = nil)
      verify_length!(stream.length)
      
      decoded_bytes = Array.new(header.width * 3, 0)
      @pixels = []
      height.times do |line_no|
        position      = line_no * (width * 3 + 1)
        line_length   = header.width * 3
        bytes         = stream.unpack("@#{position}CC#{line_length}")
        filter        = bytes.shift
        decoded_bytes = decode_scanline(filter, bytes, decoded_bytes, header)
        @pixels += decode_pixels(decoded_bytes, header)
      end
    end
    
    def decode_pixels(bytes, header)
      (0...width).map do |i|
        PNG::Color.rgb(bytes[i*3+0], bytes[i*3+1], bytes[i*3+2])
      end
    end
    
    def decode_scanline(filter, bytes, previous_bytes, header = nil)
      case filter
      when FILTER_NONE    then decode_scanline_none( bytes, previous_bytes, header)
      when FILTER_SUB     then decode_scanline_sub(  bytes, previous_bytes, header)
      when FILTER_UP      then decode_scanline_up(   bytes, previous_bytes, header)
      when FILTER_AVERAGE then raise "Average filter are not yet supported!"
      when FILTER_PAETH   then raise "Paeth filter are not yet supported!"
      else raise "Unknown filter type"
      end
    end
    
    def decode_scanline_none(bytes, previous_bytes, header = nil)
      bytes
    end
    
    def decode_scanline_sub(bytes, previous_bytes, header = nil)
      bytes.each_with_index { |b, i| bytes[i] = (b + bytes[i-3]) % 256 }
      bytes
    end
    
    def decode_scanline_up(bytes, previous_bytes, header = nil)
      bytes.each_with_index { |b, i| bytes[i] = (b + previous_bytes[i]) % 256 }
      bytes
    end
    
    def verify_length!(bytes)
      raise "Invalid stream length!" unless bytes == width * height * 3 + height
    end
    
  end
end