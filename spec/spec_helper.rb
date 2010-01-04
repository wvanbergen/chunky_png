$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'spec'

require 'chunky_png'

module ResourceFileHelper
  def resource_file(name)
    File.expand_path("../resources/#{name}", File.dirname(__FILE__))
  end
end


Spec::Runner.configure do |config|
  config.include ResourceFileHelper
end
