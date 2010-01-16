require 'spec_helper'

describe ChunkyPNG::Datastream do
  
  describe '.from_io'do
    it "should raise an error when loading a file with a bad signature" do
      filename = resource_file('damaged_signature.png')
      lambda { ChunkyPNG::Datastream.from_file(filename) }.should raise_error
    end
  
    it "should raise an error if the CRC of a chunk is incorrect" do
      filename = resource_file('damaged_chunk.png')
      lambda { ChunkyPNG::Datastream.from_file(filename) }.should raise_error
    end
  end
end
