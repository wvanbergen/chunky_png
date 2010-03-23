Gem::Specification.new do |s|
  s.name    = 'chunky_png'

  # Do not change the version and date fields by hand. This will be done
  # automatically by the gem release script.
  s.version = "0.7.1"
  s.date    = "2010-03-23"

  s.summary     = "Pure ruby library for read/write, chunk-level access to PNG files"
  s.description = <<-EOT
    This pure Ruby library can read and write PNG images without depending on an external 
    image library, like RMagick. It tries to be memory efficient and reasonably fast.
    
    It supports reading and writing all PNG variants that are defined in the specification, 
    with one limitation: only 8-bit color depth is supported. It supports all transparency, 
    interlacing and filtering options the PNG specifications allows. It can also read and 
    write textual metadata from PNG files. Low-level read/write access to PNG chunks is
    also possible.
    
    This library supports simple drawing on the image canvas and simple operations like alpha composition
    and cropping. Finally, it can import from and export to RMagick for interoperability. 
  EOT

  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@railsdoctors.com']
  s.homepage = 'http://wiki.github.com/wvanbergen/chunky_png'

  s.add_development_dependency('rspec', '>= 1.2.9')

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  # Do not change the files and test_files fields by hand. This will be done
  # automatically by the gem release script.
  s.files      = %w(spec/spec_helper.rb spec/resources/ztxt_chunk.png spec/resources/text_chunk.png spec/resources/replaced.png spec/resources/pixelstream.rgb spec/resources/indexed_4bit.png spec/resources/gray_10x10_grayscale.png spec/resources/damaged_signature.png spec/resources/damaged_chunk.png spec/resources/clock_updated.png spec/chunky_png/canvas/png_encoding_spec.rb lib/chunky_png/canvas/stream_exporting.rb spec/resources/gray_10x10.png lib/chunky_png/color.rb lib/chunky_png/canvas/operations.rb spec/resources/clock.png .gitignore spec/resources/gray_10x10_truecolor_alpha.png spec/chunky_png/canvas_spec.rb LICENSE spec/resources/gray_10x10_truecolor.png spec/resources/composited.png spec/resources/clock_mask.png spec/chunky_png/color_spec.rb spec/chunky_png/canvas/adam7_interlacing_spec.rb lib/chunky_png/chunk.rb lib/chunky_png/canvas/stream_importing.rb lib/chunky_png/canvas/png_encoding.rb lib/chunky_png/canvas/adam7_interlacing.rb spec/resources/operations.png spec/chunky_png/canvas/png_decoding_spec.rb lib/chunky_png/canvas.rb Rakefile spec/resources/transparent_gray_10x10.png spec/resources/pixelstream.rgba spec/resources/cropped.png README.rdoc spec/resources/gray_10x10_indexed.png spec/resources/clock_base.png spec/resources/16x16_non_interlaced.png spec/chunky_png_spec.rb spec/chunky_png/canvas/drawing_spec.rb lib/chunky_png/palette.rb lib/chunky_png/datastream.rb chunky_png.gemspec tasks/github-gem.rake spec/resources/pixelstream_reference.png spec/resources/lines.png spec/resources/gray_10x10_grayscale_alpha.png spec/resources/16x16_interlaced.png spec/chunky_png/image_spec.rb lib/chunky_png/canvas/drawing.rb spec/resources/clock_mask_updated.png spec/resources/adam7.png lib/chunky_png/rmagick.rb lib/chunky_png/image.rb spec/chunky_png/rmagick_spec.rb spec/chunky_png/datastream_spec.rb lib/chunky_png/canvas/png_decoding.rb lib/chunky_png.rb)
  s.test_files = %w(spec/chunky_png/canvas/png_encoding_spec.rb spec/chunky_png/canvas_spec.rb spec/chunky_png/color_spec.rb spec/chunky_png/canvas/adam7_interlacing_spec.rb spec/chunky_png/canvas/png_decoding_spec.rb spec/chunky_png_spec.rb spec/chunky_png/canvas/drawing_spec.rb spec/chunky_png/image_spec.rb spec/chunky_png/rmagick_spec.rb spec/chunky_png/datastream_spec.rb)
end