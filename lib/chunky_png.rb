require 'set'
require 'zlib'

require 'chunky_png/datastream'
require 'chunky_png/chunk'
require 'chunky_png/palette'
require 'chunky_png/pixel'
require 'chunky_png/pixel_matrix/encoding'
require 'chunky_png/pixel_matrix/decoding'
require 'chunky_png/pixel_matrix/operations'
require 'chunky_png/pixel_matrix'
require 'chunky_png/image'

# ChunkyPNG
#
# The ChunkyPNG module defines some constants that are used in the
# PNG specification.
module ChunkyPNG
  extend self

  ###################################################
  # PNG international standard defined constants
  ###################################################

  COLOR_GRAYSCALE       = 0
  COLOR_TRUECOLOR       = 2
  COLOR_INDEXED         = 3
  COLOR_GRAYSCALE_ALPHA = 4
  COLOR_TRUECOLOR_ALPHA = 6

  FILTERING_DEFAULT     = 0

  COMPRESSION_DEFAULT   = 0

  INTERLACING_NONE      = 0
  INTERLACING_ADAM7     = 1

  FILTER_NONE           = 0
  FILTER_SUB            = 1
  FILTER_UP             = 2
  FILTER_AVERAGE        = 3
  FILTER_PAETH          = 4

  def load_from_io(io)
    ChunkyPNG::Datastream.read(io)
  end

  def load_from_file(file)
    File.open(file, 'r') { |f| load_from_io(f) }
  end

  def load_from_memory(string)
    load_from_io(StringIO.new(string))
  end

  def load(arg)
    if arg.respond_to?(:read)
      load_from_io(arg)
    elsif File.exists?(arg)
      load_from_file(arg)
    else
      load_from_memory(arg)
    end
  end
end
