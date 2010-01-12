require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG do
  
  # it "should create reference images for all color modes" do
  #   image    = ChunkyPNG::Image.new(10, 10, ChunkyPNG::Pixel.rgb(100, 100, 100))
  #   [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
  #     
  #     color_mode_id = ChunkyPNG::Chunk::Header.const_get("COLOR_#{color_mode.to_s.upcase}")
  #     filename = resource_file("gray_10x10_#{color_mode}.png")
  #     File.open(filename, 'w') { |f| image.write(f, :color_mode => color_mode_id) }
  #   end
  # end
end

