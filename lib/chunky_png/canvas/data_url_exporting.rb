module ChunkyPNG
  class Canvas

    # Methods to export a canvas to a PNG data URL.
    module DataUrlExporting

      def to_data_url
        ['data:image/png;base64,', to_blob].pack('A*m0')
      end
    end
  end
end
