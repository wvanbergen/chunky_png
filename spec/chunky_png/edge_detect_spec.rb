require 'spec_helper'

begin
  require 'chunky_png/edge_detect'

  describe "Edge detection" do
  
    it "return an edge detected image" do
      orig = resource_file('engine.png')
      edge = resource_file('engine_edges.png')
      
      image = ChunkyPNG::Image.from_file(orig)
      edge_detected = image.edge_detect_with(:sobel)      
      edge_detected.save(edge)
      
      
    end
  
  end

end
