require 'spec_helper'

begin
  require 'chunky_png/edge_detect'

  describe "Edge detection" do
  
    it "should return an edge detected image with the Sobel operator" do
      orig = resource_file('engine.png')
      edge = resource_file('engine_edges_sobel.png')
      
      image = ChunkyPNG::Image.from_file(orig)
      edge_detected = image.edge_detect_with(:sobel)      
      edge_detected.save(edge)
    end

    it "should return an edge detected image with the Prewitt operator" do
      orig = resource_file('engine.png')
      edge = resource_file('engine_edges_prewitt.png')
      
      image = ChunkyPNG::Image.from_file(orig)
      edge_detected = image.edge_detect_with(:prewitt)      
      edge_detected.save(edge)
    end
  
  end

end
