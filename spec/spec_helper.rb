require 'rubygems'
require 'bundler'

Bundler.require(:default, :development)

module ResourceFileHelper
  def resource_file(name)
    File.expand_path("./resources/#{name}", File.dirname(__FILE__))
  end
  
  def suite_file(kind, file)
    File.join(suite_dir(kind), file)
  end
  
  def suite_dir(kind)
    File.expand_path("./png_suite/#{kind}", File.dirname(__FILE__))
  end
  
  def suite_files(kind, pattern = '*.png')
    Dir[File.join(suite_dir(kind), pattern)]
  end
end


module MatrixSpecHelper
  def display(canvas)
    filename = resource_file('_tmp.png')
    canvas.to_datastream.save(filename)
    `open #{filename}`
  end
  
  def reference_canvas(name)
    ChunkyPNG::Canvas.from_file(resource_file("#{name}.png"))
  end
  
  def reference_image(name)
    ChunkyPNG::Image.from_file(resource_file("#{name}.png"))
  end
end

RSpec.configure do |config|
  config.extend ResourceFileHelper
  config.include ResourceFileHelper
  config.include MatrixSpecHelper
end
