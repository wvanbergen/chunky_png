Gem::Specification.new do |s|
  s.name    = 'chunky_png'
  
  # Do not change the version and date fields by hand. This will be done
  # automatically by the gem release script.
  s.version = "0.0.1"
  s.date    = "2009-10-02"

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
  s.files      = %w(spec/spec_helper.rb lib/chunky_png/color.rb .gitignore lib/chunky_png/pixel_matrix.rb LICENSE lib/chunky_png/chunk.rb Rakefile README.rdoc lib/chunky_png/datastream.rb chunky_png.gemspec tasks/github-gem.rake lib/chunky_png/image.rb spec/unit/pixel_matrix_spec.rb lib/chunky_png.rb)
  s.test_files = %w(spec/unit/pixel_matrix_spec.rb)
end