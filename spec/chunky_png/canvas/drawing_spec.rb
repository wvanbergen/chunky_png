require 'spec_helper'

describe ChunkyPNG::Canvas::Drawing do
  
  describe '#point' do
    subject { ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color.rgb(200, 150, 100)) }
    
    it "should compose colors correctly" do
      subject.point(0,0, ChunkyPNG::Color.rgba(100, 150, 200, 128))
      subject['0,0'].should == ChunkyPNG::Color.rgb(150, 150, 150)
    end
    
    it "should return the composed color" do
      subject.point(0, 0, ChunkyPNG::Color.rgba(100, 150, 200, 128)).should == ChunkyPNG::Color.rgb(150, 150, 150)
    end
    
    it "should accept point-like arguments as well" do
      lambda { subject.point('0,0', ChunkyPNG::Color.rgba(100, 150, 200, 128)) }.should change { subject['0,0'] }
      lambda { subject.point({:x => 0, :y => 0}, ChunkyPNG::Color.rgba(100, 150, 200, 128)) }.should change { subject['0,0'] }
      lambda { subject.point(ChunkyPNG::Point.new(0, 0), ChunkyPNG::Color.rgba(100, 150, 200, 128)) } .should change { subject['0,0'] }
    end
    
    it "should do nothing when the coordinates are out of bounds" do
      subject.point(1, -1, ChunkyPNG::Color::BLACK).should be_nil
      lambda { subject.point(1, -1, ChunkyPNG::Color::BLACK) }.should_not change { subject['0,0'] }
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
    
    it "should draw partial lines if the coordinates are partially out of bounds" do
      canvas = ChunkyPNG::Canvas.new(1, 2, ChunkyPNG::Color::WHITE)
      canvas.line(-5, -5, 0, 0, ChunkyPNG::Color::BLACK)
      canvas.pixels.should == [ChunkyPNG::Color::BLACK, ChunkyPNG::Color::WHITE]
    end
    
    it "should return itself to allow chaining" do
      canvas = ChunkyPNG::Canvas.new(16, 16, ChunkyPNG::Color::WHITE)
      canvas.line(1, 1, 10, 10, ChunkyPNG::Color::BLACK).should equal(canvas)
    end
  end
  
  describe '#rect' do
    it "should draw a rectangle with the correct colors" do
      canvas = ChunkyPNG::Canvas.new(16, 16, ChunkyPNG::Color::WHITE)
      canvas.rect(1, 1, 10, 10, ChunkyPNG::Color.rgb(0, 255, 0), ChunkyPNG::Color.rgba(255, 0, 0, 100))
      canvas.rect(5, 5, 14, 14, ChunkyPNG::Color.rgb(0, 0, 255), ChunkyPNG::Color.rgba(255, 255, 0, 100))
      canvas.should == reference_canvas('rect')
    end
    
    it "should return itself to allow chaining" do
      canvas = ChunkyPNG::Canvas.new(16, 16, ChunkyPNG::Color::WHITE)
      canvas.rect(1, 1, 10, 10).should equal(canvas)
    end
    
    it "should draw partial rectangles if the coordinates are partially out of bounds" do
      canvas = ChunkyPNG::Canvas.new(1, 1)
      canvas.rect(0, 0, 10, 10, ChunkyPNG::Color::BLACK, ChunkyPNG::Color::WHITE)
      canvas[0, 0].should == ChunkyPNG::Color::BLACK
    end
    
    it "should draw the rectangle fill only if the coordinates are fully out of bounds" do
      canvas = ChunkyPNG::Canvas.new(1, 1)
      canvas.rect(-10, -10, 10, 10, ChunkyPNG::Color::BLACK, ChunkyPNG::Color::WHITE)
      canvas[0, 0].should == ChunkyPNG::Color::WHITE
    end
  end
  
  describe '#circle' do
    subject { ChunkyPNG::Canvas.new(32, 32, ChunkyPNG::Color.rgba(0, 0, 255, 128)) } 
    
    it "should draw circles" do
      subject.circle(11, 11, 10, ChunkyPNG::Color.rgba(255, 0, 0, 128))
      subject.circle(21, 21, 10, ChunkyPNG::Color.rgba(0, 255, 0, 128))
      subject.should == reference_canvas('circles')
    end
    
    it "should draw partial circles when going of the canvas bounds" do
      subject.circle(0, 0, 10)
      subject.circle(31, 16, 10)
      subject.should == reference_canvas('partial_circles')
    end
    
    it "should raise an exception when a brush is used" do
      lambda { subject.circle(21, 21, 10, ChunkyPNG::Color::BLACK, ChunkyPNG::Color::BLACK) }.should raise_error(ChunkyPNG::NotSupported)
    end
    
    it "should return itself to allow chaining" do
      subject.circle(10, 10, 5).should equal(subject)
    end
  end
end
