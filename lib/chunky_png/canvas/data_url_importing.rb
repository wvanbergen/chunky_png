module ChunkyPNG
  class Canvas

    # Methods to export a canvas to a PNG data URL.
    module DataUrlImporting

      # Exports the canvas as a data url (e.g. data:image/png;base64,<data>) that can
      # easily be used inline in CSS or HTML.
      # @return [String] The canvas formatted as a data URL string.
      def from_data_url(string)
        if string =~ %r[^data:image/png;base64,((?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=))$]
          from_blob($1.unpack('m').first)
        else
          raise SignatureMismatch, "The string was not a properly formatted data URL for a PNG image."
        end
      end
    end
  end
end
