# directly derived from SKUI, by Thomas Thomassen
# https://github.com/thomthom/SKUI.git
module ChunkyPNG

  # Method to load ChunkyPNG into a given namespace - ensuring ChunkyPNG can be
  # distributed easily within other projects.
  #
  # @example
  #   module Example
  #     load File.join( skui_path, 'ChunkyPNG', 'embed_chunky_png.rb' )
  #     ::ChunkyPNG.embed_in( self )
  #     # ChunkyPNG module is now available under Example::ChunkyPNG
  #   end
  #
  # @param [Module] context
  #
  # @return [Boolean]
  # @since 1.0.0
  def self.embed_in( context )
    # Temporarily rename existing root ChunkyPNG.
    Object.send( :const_set, :ChunkyPNG_Temp, ChunkyPNG )
    Object.send( :remove_const, :ChunkyPNG )
    # Load ChunkyPNG for this ChunkyPNG implementation.
    path = File.dirname( __FILE__ )
    core = File.join( path, 'chunky_png.rb' )
    loaded = require( core )
    # One can only embed ChunkyPNG into one context per ChunkyPNG installation. This is
    # because `require` prevents the files to be loaded multiple times.
    # This should not be an issue though as an extension that implements ChunkyPNG
    # should only use the ChunkyPNG version it distribute itself.
    if loaded
      # Move ChunkyPNG to the target context.
      context.send( :const_set, :ChunkyPNG, ChunkyPNG )
      Object.send( :remove_const, :ChunkyPNG )
      true
    else
      false
    end
  ensure
    # Restore root SKUI and clean up temp namespace.
    Object.send( :const_set, :ChunkyPNG, ChunkyPNG_Temp )
    Object.send( :remove_const, :ChunkyPNG_Temp )
  end

end # module