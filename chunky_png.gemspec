Gem::Specification.new do |s|
  s.name    = 'chunky_png'
  
  # Do not change the version and date fields by hand. This will be done
  # automatically by the gem release script.
  s.version = "0.0.4"
  s.date    = "2010-01-13"

  s.summary     = "Pure ruby library for read/write, chunk-level access to PNG files"
  s.description = "Pure ruby library for read/write, chunk-level access to PNG files"

  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@railsdoctors.com']
  s.homepage = 'http://wiki.github.com/wvanbergen/chunky_png'

  s.add_development_dependency('rspec', '>= 1.2.9')

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  # Do not change the files and test_files fields by hand. This will be done
  # automatically by the gem release script.
  s.files      = %w(spec/spec_helper.rb spec/resources/pixelstream.rgb spec/resources/gray_10x10_grayscale.png spec/resources/gray_10x10.png .gitignore spec/resources/gray_10x10_truecolor_alpha.png lib/chunky_png/pixel_matrix.rb LICENSE spec/resources/gray_10x10_truecolor.png lib/chunky_png/pixel_matrix/decoding.rb lib/chunky_png/chunk.rb spec/unit/encoding_spec.rb spec/resources/operations.png Rakefile spec/resources/transparent_gray_10x10.png README.rdoc spec/resources/gray_10x10_indexed.png spec/resources/16x16_non_interlaced.png spec/integration/image_spec.rb lib/chunky_png/pixel_matrix/operations.rb lib/chunky_png/pixel.rb lib/chunky_png/palette.rb lib/chunky_png/datastream.rb chunky_png.gemspec tasks/github-gem.rake spec/unit/decoding_spec.rb spec/resources/pixelstream_reference.png spec/resources/gray_10x10_grayscale_alpha.png spec/resources/16x16_interlaced.png spec/resources/adam7.png lib/chunky_png/pixel_matrix/encoding.rb lib/chunky_png/image.rb spec/unit/pixel_spec.rb spec/unit/pixel_matrix_spec.rb lib/chunky_png.rb)
  s.test_files = %w(spec/unit/encoding_spec.rb spec/integration/image_spec.rb spec/unit/decoding_spec.rb spec/unit/pixel_spec.rb spec/unit/pixel_matrix_spec.rb)
end