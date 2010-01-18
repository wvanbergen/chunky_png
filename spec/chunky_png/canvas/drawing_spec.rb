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
end
