Gem::Specification.new do |s|
  s.name    = 'chunky_png'

  # Do not change the version and date fields by hand. This will be done
  # automatically by the gem release script.
  s.version = "0.9.2"
  s.date    = "2010-09-17"

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

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '>= 1.3')
  s.add_development_dependency('git')

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc', 'BENCHMARKS.rdoc']

  # Do not change the files and test_files fields by hand. This will be done
  # automatically by the gem release script.
  s.files      = %w(tasks/github-gem.rake lib/chunky_png/canvas.rb spec/resources/composited.png lib/chunky_png/canvas/drawing.rb spec/resources/gray_10x10_grayscale_alpha.png spec/resources/cropped.png LICENSE spec/resources/clock_mask_updated.png spec/resources/pixelstream.rgba Gemfile spec/resources/clock_rotate_right.png spec/resources/ztxt_chunk.png spec/resources/transparent_gray_10x10.png lib/chunky_png/canvas/png_decoding.rb lib/chunky_png/image.rb spec/resources/lines.png spec/resources/clock_mask.png spec/resources/clock_stubbed.png spec/resources/pixelstream.rgb tasks/benchmarks.rake spec/resources/indexed_4bit.png spec/resources/text_chunk.png chunky_png.gemspec benchmarks/decoding_benchmark.rb spec/resources/gray_10x10_truecolor_alpha.png lib/chunky_png/color.rb spec/resources/damaged_chunk.png spec/resources/rect.png README.rdoc lib/chunky_png/canvas/stream_exporting.rb spec/resources/clock_flip_horizontally.png lib/chunky_png/canvas/stream_importing.rb spec/chunky_png/canvas/adam7_interlacing_spec.rb spec/spec_helper.rb lib/chunky_png/rmagick.rb Gemfile.lock Rakefile spec/chunky_png/canvas/png_decoding_spec.rb lib/chunky_png.rb lib/chunky_png/canvas/png_encoding.rb .gitignore spec/resources/16x16_interlaced.png spec/chunky_png/canvas/drawing_spec.rb spec/chunky_png/canvas/png_encoding_spec.rb spec/resources/adam7.png lib/chunky_png/palette.rb spec/resources/gray_10x10_indexed.png spec/chunky_png/canvas_spec.rb spec/resources/clock.png benchmarks/encoding_benchmark.rb spec/chunky_png/image_spec.rb spec/resources/clock_rotate_180.png spec/resources/clock_rotate_left.png BENCHMARKS.rdoc spec/resources/16x16_non_interlaced.png lib/chunky_png/chunk.rb spec/chunky_png/canvas/operations_spec.rb spec/resources/gray_10x10_truecolor.png spec/resources/gray_10x10_grayscale.png spec/resources/pixelstream_reference.png spec/chunky_png_spec.rb spec/resources/operations.png spec/resources/clock_flip_vertically.png spec/chunky_png/rmagick_spec.rb lib/chunky_png/datastream.rb spec/resources/clock_base.png lib/chunky_png/canvas/operations.rb spec/resources/replaced.png spec/resources/clock_updated.png spec/resources/damaged_signature.png spec/chunky_png/datastream_spec.rb lib/chunky_png/canvas/adam7_interlacing.rb spec/chunky_png/color_spec.rb spec/resources/gray_10x10.png)
  s.test_files = %w(spec/chunky_png/canvas/adam7_interlacing_spec.rb spec/chunky_png/canvas/png_decoding_spec.rb spec/chunky_png/canvas/drawing_spec.rb spec/chunky_png/canvas/png_encoding_spec.rb spec/chunky_png/canvas_spec.rb spec/chunky_png/image_spec.rb spec/chunky_png/canvas/operations_spec.rb spec/chunky_png_spec.rb spec/chunky_png/rmagick_spec.rb spec/chunky_png/datastream_spec.rb spec/chunky_png/color_spec.rb)
end
