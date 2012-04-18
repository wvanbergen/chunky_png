require 'spec_helper'

begin
  describe "Edge detection" do
  
    it "should return an edge detected image with the Sobel operator" do
      orig = resource_file('engine.png')
      edge = resource_file('engine_edges_sobel.png')
      image = ChunkyPNG::Image.from_file(orig)
      edge_detected = image.edge_detect 
      edge_detected.save(edge)    
      reference_image('engine_edges_sobel').should == reference_image('engine_edges_sobel_ref')
    end

    it "should return an edge detected image with the Prewitt operator" do
      orig = resource_file('engine.png')
      edge = resource_file('engine_edges_prewitt.png')      
      image = ChunkyPNG::Image.from_file(orig)
      edge_detected = image.edge_detect(:prewitt)  
      edge_detected.save(edge)    
      reference_image('engine_edges_prewitt').should == reference_image('engine_edges_prewitt_ref')      
    end
  end

end
