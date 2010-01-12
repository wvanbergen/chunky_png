module ChunkyPNG
  
  class PixelMatrix
    
    FILTER_NONE    = 0
    FILTER_SUB     = 1
    FILTER_UP      = 2
    FILTER_AVERAGE = 3
    FILTER_PAETH   = 4
    
    attr_reader :width, :height, :pixels
    
    def self.load(header, content)
      matrix = self.new(header.width, header.height)
      matrix.decode_pixelstream(content, header)
      return matrix
    end
    
    def [](x, y)
      @pixels[y * width + x]
    end
    
    def each_scanline(&block)
      height.times do |i|
        scanline = @pixels[width * i, width]
        yield(scanline)
      end
    end
    
    def []=(x, y, pixel)
      @pixels[y * width + x] = pixel
    end
    
    def initialize(width, height, background_color = ChunkyPNG::Pixel::WHITE)
      @width, @height = width, height
      @pixels = Array.new(width * height, background_color)
    end

    def decode_pixelstream(stream, header = nil)
      verify_length!(stream.length)
      @pixels = []
      
      decoded_bytes = Array.new(header.width * 3, 0)
      height.times do |line_no|
        position       = line_no * (width * 3 + 1)
        line_length    = header.width * 3
        bytes          = stream.unpack("@#{position}CC#{line_length}")
        filter         = bytes.shift
        decoded_bytes  = decode_scanline(filter, bytes, decoded_bytes, header)
        decoded_colors = decode_colors(decoded_bytes, header)
        @pixels += decoded_colors.map { |c| Pixel.new(c) }
      end
      
      raise "Invalid amount of pixels" if @pixels.size != width * height
    end
    
    def decode_colors(bytes, header)
      (0...width).map { |i| ChunkyPNG::Pixel.rgb(bytes[i*3+0], bytes[i*3+1], bytes[i*3+2]) }
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
      bytes.each_with_index { |b, i| bytes[i] = (b + (i >= 3 ? bytes[i-3] : 0)) % 256 }
      bytes
    end
    
    def decode_scanline_up(bytes, previous_bytes, header = nil)
      bytes.each_with_index { |b, i| bytes[i] = (b + previous_bytes[i]) % 256 }
      bytes
    end
    
    def verify_length!(bytes_count)
      raise "Invalid stream length!" unless bytes_count == width * height * 3 + height
    end
    
    def encode_scanline(filter, bytes, previous_bytes = nil, header = nil)
      case filter
      when FILTER_NONE    then encode_scanline_none( bytes, previous_bytes, header)
      when FILTER_SUB     then encode_scanline_sub(  bytes, previous_bytes, header)
      when FILTER_UP      then encode_scanline_up(   bytes, previous_bytes, header)
      when FILTER_AVERAGE then raise "Average filter are not yet supported!"
      when FILTER_PAETH   then raise "Paeth filter are not yet supported!"
      else raise "Unknown filter type"
      end
    end
    
    def encode_scanline_none(bytes, previous_bytes = nil, header = nil)
      [FILTER_NONE] + bytes
    end
    
    def encode_scanline_sub(bytes, previous_bytes = nil, header = nil)
      encoded = (3...bytes.length).map { |n| (bytes[n-3] - bytes[n]) % 256 }
      [FILTER_SUB] + bytes[0...3] + encoded
    end
    
    def encode_scanline_up(bytes, previous_bytes, header = nil)
      encoded = (0...bytes.length).map { |n| previous_bytes[n] - bytes[n] % 256 }
      [FILTER_UP] + encoded
    end
    
    def palette
      ChunkyPNG::Palette.from_pixels(@pixels)
    end
    
    def opaque?
      pixels.all? { |pixel| pixel.opaque? }
    end
    
    def indexable?
      palette.indexable?
    end
    
    def to_indexed_pixelstream(palette)
      stream = ""
      each_scanline do |line|
        bytes  = line.map { |pixel| pixel.index(palette) }
        stream << encode_scanline(FILTER_NONE, bytes).pack('C*')
      end
      return stream
    end
    
    def to_rgb_pixelstream
      stream = ""
      each_scanline do |line|
        bytes = line.map { |pixel| pixel.to_rgb_bytes }.flatten
        stream << encode_scanline(FILTER_NONE, bytes).pack('C*')
      end
      return stream
    end
    
    def to_rgba_pixelstream
      stream = ""
      each_scanline do |line|
        bytes = line.map { |pixel| pixel.to_rgba_bytes }.flatten
        stream << encode_scanline(FILTER_NONE, bytes).pack('C*')
      end
      return stream
    end
  end
end
