require 'set'
require 'zlib'

require 'chunky_png/datastream'
require 'chunky_png/chunk'
require 'chunky_png/palette'
require 'chunky_png/color'
require 'chunky_png/pixel_matrix/png_encoding'
require 'chunky_png/pixel_matrix/png_decoding'
require 'chunky_png/pixel_matrix/adam7_interlacing'
require 'chunky_png/pixel_matrix/operations'
require 'chunky_png/pixel_matrix/drawing'
require 'chunky_png/pixel_matrix'
require 'chunky_png/image'

# ChunkyPNG
#
# The ChunkyPNG module defines some constants that are used in the
# PNG specification.
module ChunkyPNG

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
