require 'set'
require 'zlib'
require 'stringio'
require 'enumerator'

require 'chunky_png/datastream'
require 'chunky_png/chunk'
require 'chunky_png/palette'
require 'chunky_png/color'
require 'chunky_png/canvas/png_encoding'
require 'chunky_png/canvas/png_decoding'
require 'chunky_png/canvas/adam7_interlacing'
require 'chunky_png/canvas/stream_exporting'
require 'chunky_png/canvas/stream_importing'
require 'chunky_png/canvas/operations'
require 'chunky_png/canvas/drawing'
require 'chunky_png/canvas'
require 'chunky_png/image'

# ChunkyPNG - the pury ruby library to access PNG files.
#
# The ChunkyPNG module defines some constants that are used in the
# PNG specification.
#
# @author Willem van Bergen
module ChunkyPNG

  # The current version of ChunkyPNG. This value will be updated automatically
  # by them gem:release rake task.
  VERSION = "0.6.0"

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
end
