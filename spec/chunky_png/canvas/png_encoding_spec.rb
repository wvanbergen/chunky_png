require 'spec_helper'

describe ChunkyPNG::Canvas::PNGEncoding do
  include ChunkyPNG::Canvas::PNGEncoding

  describe '.encode_png' do
    [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode_name|
      it "should encode an image with color mode #{color_mode_name} correctly" do
        filename = resource_file("_tmp_#{color_mode_name}.png")
        canvas = ChunkyPNG::Canvas.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
        color_mode = ChunkyPNG.const_get("COLOR_#{color_mode_name.to_s.upcase}")
        canvas.save(filename, :color_mode => color_mode)
        
        ds = ChunkyPNG::Datastream.from_file(filename)
        ds.header_chunk.color.should == color_mode
        ChunkyPNG::Canvas.from_datastream(ds).should == ChunkyPNG::Canvas.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
        
        File.unlink(filename)
      end
    end
    
    it "should encode an image with interlacing correctly" do
      input_canvas = ChunkyPNG::Canvas.from_file(resource_file('operations.png'))
      filename = resource_file("_tmp_interlaced.png")
      input_canvas.save(filename, :interlace => true)
      
      ds = ChunkyPNG::Datastream.from_file(filename)
      ds.header_chunk.interlace.should == ChunkyPNG::INTERLACING_ADAM7
      ChunkyPNG::Canvas.from_datastream(ds).should == input_canvas

      File.unlink(filename)
    end

    it "should save an image using the normal routine correctly" do
      canvas = reference_canvas('operations')
      Zlib::Deflate.should_receive(:deflate).with(anything, Zlib::DEFAULT_COMPRESSION).and_return('')
      canvas.to_blob
    end

    it "should save an image using the :fast_rgba routine correctly" do
      canvas = reference_canvas('operations')
      canvas.should_not_receive(:encode_png_str_scanline_none)
      canvas.should_not_receive(:encode_png_str_scanline_sub)
      canvas.should_not_receive(:encode_png_str_scanline_up)
      canvas.should_not_receive(:encode_png_str_scanline_average)
      canvas.should_not_receive(:encode_png_str_scanline_paeth)
      Zlib::Deflate.should_receive(:deflate).with(anything, Zlib::BEST_SPEED).and_return('')
      canvas.to_blob(:fast_rgba)
    end

    it "should save an image using the :good_compression routine correctly" do
      canvas = reference_canvas('operations')
      canvas.should_not_receive(:encode_png_str_scanline_none)
      canvas.should_not_receive(:encode_png_str_scanline_sub)
      canvas.should_not_receive(:encode_png_str_scanline_up)
      canvas.should_not_receive(:encode_png_str_scanline_average)
      canvas.should_not_receive(:encode_png_str_scanline_paeth)
      Zlib::Deflate.should_receive(:deflate).with(anything, Zlib::BEST_COMPRESSION).and_return('')
      canvas.to_blob(:good_compression)
    end

    it "should save an image using the :best_compression routine correctly" do
      canvas = reference_canvas('operations')
      canvas.should_receive(:encode_png_str_scanline_paeth).exactly(canvas.height).times
      Zlib::Deflate.should_receive(:deflate).with(anything, Zlib::BEST_COMPRESSION).and_return('')
      canvas.to_blob(:best_compression)
    end
  end

  describe '#encode_png_image_pass_to_stream' do
    before { @canvas = ChunkyPNG::Canvas.new(2, 2, ChunkyPNG::Color.rgba(1, 2, 3, 4)) }

    it "should encode using RGBA / no filtering mode correctly" do
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_TRUECOLOR_ALPHA, ChunkyPNG::FILTER_NONE)
      stream.should == "\0\1\2\3\4\1\2\3\4\0\1\2\3\4\1\2\3\4"
    end

    it "should encode using RGBA / SUB filtering mode correctly" do
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_TRUECOLOR_ALPHA, ChunkyPNG::FILTER_SUB)
      stream.should == "\1\1\2\3\4\0\0\0\0\1\1\2\3\4\0\0\0\0"
    end

    it "should encode using RGBA / UP filtering mode correctly" do
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_TRUECOLOR_ALPHA, ChunkyPNG::FILTER_UP)
      stream.should == "\2\1\2\3\4\1\2\3\4\2\0\0\0\0\0\0\0\0"
    end

    it "should encode using RGBA / AVERAGE filtering mode correctly" do
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_TRUECOLOR_ALPHA, ChunkyPNG::FILTER_AVERAGE)
      stream.should == "\3\1\2\3\4\1\1\2\2\3\1\1\2\2\0\0\0\0"
    end

    it "should encode using RGB / no filtering mode correctly" do
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_TRUECOLOR, ChunkyPNG::FILTER_NONE)
      stream.should == "\0\1\2\3\1\2\3\0\1\2\3\1\2\3"
    end

    it "should encode using indexed / no filtering mode correctly" do
      @canvas.stub(:encoding_palette).and_return(mock('Palette', :index => 1))
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_INDEXED, ChunkyPNG::FILTER_NONE)
      stream.should == "\0\1\1\0\1\1"
    end

    it "should encode using indexed / PAETH filtering mode correctly" do
      @canvas.stub(:encoding_palette).and_return(mock('Palette', :index => 1))
      @canvas.encode_png_image_pass_to_stream(stream = ChunkyPNG::Datastream.empty_bytearray, ChunkyPNG::COLOR_INDEXED, ChunkyPNG::FILTER_PAETH)
      stream.should == "\4\1\0\4\0\0"
    end
  end

  describe '#encode_png_str_scanline' do

    it "should encode a scanline without filtering correctly" do
      stream = [ChunkyPNG::FILTER_NONE, 0, 0, 0, 1, 1, 1, 2, 2, 2].pack('C*')
      encode_png_str_scanline_none(stream, 0, nil, 9, 3)
      stream.unpack('C*').should == [ChunkyPNG::FILTER_NONE, 0, 0, 0, 1, 1, 1, 2, 2, 2]
    end

    it "should encode a scanline with sub filtering correctly" do
      stream = [ChunkyPNG::FILTER_NONE, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                ChunkyPNG::FILTER_NONE, 255, 255, 255, 255, 255, 255, 255, 255, 255].pack('C*')

      # Check line with previous line
      encode_png_str_scanline_sub(stream, 10, 0, 9, 3)
      stream.unpack('@10C10').should == [ChunkyPNG::FILTER_SUB, 255, 255, 255, 0, 0, 0, 0, 0, 0]

      # Check line without previous line
      encode_png_str_scanline_sub(stream, 0, nil, 9, 3)
      stream.unpack('@0C10').should == [ChunkyPNG::FILTER_SUB, 255, 255, 255, 0, 0, 0, 0, 0, 0]
    end

    it "should encode a scanline with up filtering correctly" do
      stream = [ChunkyPNG::FILTER_NONE, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                ChunkyPNG::FILTER_NONE, 255, 255, 255, 255, 255, 255, 255, 255, 255].pack('C*')

      # Check line with previous line
      encode_png_str_scanline_up(stream, 10, 0, 9, 3)
      stream.unpack('@10C10').should == [ChunkyPNG::FILTER_UP, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      # Check line without previous line
      encode_png_str_scanline_up(stream, 0, nil, 9, 3)
      stream.unpack('@0C10').should == [ChunkyPNG::FILTER_UP, 255, 255, 255, 255, 255, 255, 255, 255, 255]
    end
    
    it "should encode a scanline with average filtering correctly" do
      stream = [ChunkyPNG::FILTER_NONE, 10, 20, 30, 40, 50, 60, 70, 80,   80, 100, 110, 120,
                ChunkyPNG::FILTER_NONE,  5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165].pack('C*')

      # Check line with previous line
      encode_png_str_scanline_average(stream, 13, 0, 12, 3)
      stream.unpack('@13C13').should == [ChunkyPNG::FILTER_AVERAGE, 0, 0, 10, 23, 15, 13, 23, 63, 38, 60, 253, 53]

      # Check line without previous line
      encode_png_str_scanline_average(stream, 0, nil, 12, 3)
      stream.unpack('@0C13').should == [ChunkyPNG::FILTER_AVERAGE, 10, 20, 30, 35, 40, 45, 50, 55, 50, 65, 70, 80]
    end
    
    it "should encode a scanline with paeth filtering correctly" do
      stream = [ChunkyPNG::FILTER_NONE, 10, 20, 30, 40, 50, 60, 70,  80, 80, 100, 110, 120,
                ChunkyPNG::FILTER_NONE, 10, 20, 40, 60, 60, 60, 70, 120, 90, 120,  54, 120].pack('C*')

      # Check line with previous line
      encode_png_str_scanline_paeth(stream, 13, 0, 12, 3)
      stream.unpack('@13C13').should == [ChunkyPNG::FILTER_PAETH, 0, 0, 10, 20, 10, 0, 0, 40, 10, 20, 190, 0]

      # Check line without previous line
      encode_png_str_scanline_paeth(stream, 0, nil, 12, 3)
      stream.unpack('@0C13').should == [ChunkyPNG::FILTER_PAETH, 10, 20, 30, 30, 30, 30, 30, 30, 20, 30, 30, 40]
    end
  end
end
