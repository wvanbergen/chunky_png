require 'rubygems'
require 'bundler'

Bundler.setup

require 'benchmark'
require 'chunky_png'

filename = File.join(File.dirname(__FILE__), '..', 'spec', 'resources', 'pixelstream_reference.png')
image = ChunkyPNG::Canvas.from_file(filename)

puts ":no_compression   : %d byte" % image.to_blob(:no_compression).bytesize
puts ":fast_rgba        : %d byte" % image.to_blob(:fast_rgba).bytesize
puts ":fast_rgb         : %d byte" % image.to_blob(:fast_rgb).bytesize
puts ":good_compression : %d byte" % image.to_blob(:good_compression).bytesize
puts ":best_compression : %d byte" % image.to_blob(:best_compression).bytesize
