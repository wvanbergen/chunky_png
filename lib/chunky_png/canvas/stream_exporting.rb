module ChunkyPNG
  class Canvas

    # Methods to save load a canvas from to stream, encoded in RGB, RGBA, BGR or ABGR format.
    module StreamExporting

      # Creates an RGB-formatted pixelstream with the pixel data from this canvas.
      #
      # Note that this format is fast but bloated, because no compression is used
      # and the internal representation is left intact. To reconstruct the
      # canvas, the width and height should be known.
      #
      # @return [String] The RGBA-formatted pixel data.
      def to_rgba_stream
        pixels.pack('N*')
      end

      # Creates an RGB-formatted pixelstream with the pixel data from this canvas.
      #
      # Note that this format is fast but bloated, because no compression is used
      # and the internal representation is almost left intact. To reconstruct
      # the canvas, the width and height should be known.
      #
      # @return [String] The RGB-formatted pixel data.
      def to_rgb_stream
        pixels.pack('NX' * (width * height))
      end

      # Creates an ABGR-formatted pixelstream with the pixel data from this canvas.
      #
      # Note that this format is fast but bloated, because no compression is used
      # and the internal representation is left intact. To reconstruct the
      # canvas, the width and height should be known.
      #
      # @return [String] The RGBA-formatted pixel data.
      def to_abgr_stream
        pixels.pack('V*')
      end
    end
  end
end
