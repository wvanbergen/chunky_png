require 'spec_helper'

describe ChunkyPNG::Canvas::Drawing do
  
  describe '#point' do
    it "should compose colors correctly" do
      canvas = ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color.rgb(200, 150, 100))
      canvas.point(0,0, ChunkyPNG::Color.rgba(100, 150, 200, 128))
      canvas[0,0].should == ChunkyPNG::Color.rgb(150, 150, 150)
    end
  end
  
  describe '#line' do
    it "should draw lines correctly with anti-aliasing" do
      canvas = ChunkyPNG::Canvas.new(32, 32, ChunkyPNG::Color::WHITE)
      
      canvas.line( 0,  0, 31, 31, ChunkyPNG::Color::BLACK)
      canvas.line( 0, 31, 31,  0, ChunkyPNG::Color::BLACK)
      canvas.line(15, 31, 15,  0, ChunkyPNG::Color.rgba(200,   0,   0, 128))
      canvas.line( 0, 15, 31, 15, ChunkyPNG::Color.rgba(200,   0,   0, 128))
      canvas.line( 0, 15, 31, 31, ChunkyPNG::Color.rgba(  0, 200,   0, 128))
      canvas.line( 0, 15, 31,  0, ChunkyPNG::Color.rgba(  0, 200,   0, 128))
      canvas.line(15,  0, 31, 31, ChunkyPNG::Color.rgba(  0,   0, 200, 128))
      canvas.line(15,  0,  0, 31, ChunkyPNG::Color.rgba(  0,   0, 200, 128))
      
      canvas.should == reference_canvas('lines')
    end
  end
  
  describe '#rect' do
    it "should draw a rectangle with the correct colors" do
      canvas = ChunkyPNG::Canvas.new(16, 16, ChunkyPNG::Color::WHITE)
      canvas.rect(1, 1, 10, 10, ChunkyPNG::Color.rgb(0, 255, 0), ChunkyPNG::Color.rgba(255, 0, 0, 100))
      canvas.rect(5, 5, 14, 14, ChunkyPNG::Color.rgb(0, 0, 255), ChunkyPNG::Color.rgba(255, 255, 0, 100))
      canvas.should == reference_canvas('rect')
    end
  end
end
