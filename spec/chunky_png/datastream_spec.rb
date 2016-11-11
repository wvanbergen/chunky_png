require 'spec_helper'

describe ChunkyPNG::Datastream do

  describe '.from_io'do
    it "should raise an error when loading a file with a bad signature" do
      filename = resource_file('damaged_signature.png')
      expect { ChunkyPNG::Datastream.from_file(filename) }.to raise_error(ChunkyPNG::SignatureMismatch)
    end

    it "should raise an error if the CRC of a chunk is incorrect" do
      filename = resource_file('damaged_chunk.png')
      expect { ChunkyPNG::Datastream.from_file(filename) }.to raise_error(ChunkyPNG::CRCMismatch)
    end

    it "should raise an error for a stream that is too short" do
      stream = StringIO.new
      expect { ChunkyPNG::Datastream.from_io(stream) }.to raise_error(ChunkyPNG::SignatureMismatch)
    end

    it "should read a stream with trailing data without failing" do
      filename = resource_file('trailing_bytes_after_iend_chunk.png')
      image = ChunkyPNG::Datastream.from_file(filename)
      expect(image).to be_instance_of(ChunkyPNG::Datastream)
    end
  end

  describe '#metadata' do
    it "should load uncompressed tXTt chunks correctly" do
      filename = resource_file('text_chunk.png')
      ds = ChunkyPNG::Datastream.from_file(filename)
      expect(ds.metadata['Title']).to  eql 'My amazing icon!'
      expect(ds.metadata['Author']).to eql "Willem van Bergen"
    end

    it "should load compressed zTXt chunks correctly" do
      filename = resource_file('ztxt_chunk.png')
      ds = ChunkyPNG::Datastream.from_file(filename)
      expect(ds.metadata['Title']).to eql 'PngSuite'
      expect(ds.metadata['Copyright']).to eql "Copyright Willem van Schaik, Singapore 1995-96"
    end
  end

  describe '#physical_chunk' do
    it 'should read and write pHYs chunks correctly' do
      filename = resource_file('clock.png')
      ds = ChunkyPNG::Datastream.from_file(filename)
      expect(ds.physical_chunk.unit).to eql :meters
      expect(ds.physical_chunk.dpix.round).to eql 72
      expect(ds.physical_chunk.dpiy.round).to eql 72
      ds = ChunkyPNG::Datastream.from_blob(ds.to_blob)
      expect(ds.physical_chunk).not_to be_nil
    end

    it 'should raise ChunkyPNG::UnitsUnknown if we request dpi but the units are unknown' do
      physical_chunk = ChunkyPNG::Chunk::Physical.new(2835, 2835, :unknown)
      expect{physical_chunk.dpix}.to raise_error(ChunkyPNG::UnitsUnknown)
      expect{physical_chunk.dpiy}.to raise_error(ChunkyPNG::UnitsUnknown)
    end
  end
end
