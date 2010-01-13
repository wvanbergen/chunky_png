$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'spec'

require 'chunky_png'

module ResourceFileHelper
  def resource_file(name)
    File.expand_path("./resources/#{name}", File.dirname(__FILE__))
  end
end


module MatrixDisplayingHelper
  def display(matrix)
    image = ChunkyPNG::Image.from_pixel_matrix(matrix)
    filename = resource_file('_tmp.png')
    image.save(filename)
    `open #{filename}`
  end
end

Spec::Runner.configure do |config|
  config.include ResourceFileHelper
  config.include MatrixDisplayingHelper
end
