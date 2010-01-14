require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe ChunkyPNG do

  # it "should create reference images for all color modes" do
  #   image    = ChunkyPNG::Image.new(10, 10, ChunkyPNG::Color.rgb(100, 100, 100))
  #   [:indexed, :grayscale, :grayscale_alpha, :truecolor, :truecolor_alpha].each do |color_mode|
  #
  #     color_mode_id = ChunkyPNG::Chunk::Header.const_get("COLOR_#{color_mode.to_s.upcase}")
  #     filename = resource_file("gray_10x10_#{color_mode}.png")
  #     image.save(filename, :color_mode => color_mode_id)
  #   end
  # end

  # it "should create a reference image for operations" do
  #   image = ChunkyPNG::Image.new(16, 16, ChunkyPNG::Color::WHITE)
  #   r = 0
  #   image.width.times do |x|
  #     g = 0
  #     image.height.times do |y|
  #       image[x, y] = ChunkyPNG::Color.rgb(r, g, 255)
  #       g += 16
  #     end
  #     r += 16
  #   end
  #   filename = resource_file('operations.png')
  #   image.save(filename)
  #   # `open #{filename}`
  # end
end

