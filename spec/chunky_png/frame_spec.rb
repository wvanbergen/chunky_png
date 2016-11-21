require 'spec_helper'

describe ChunkyPNG::Frame do
  describe '.from_canvas' do
    let(:canvas) { ChunkyPNG::Canvas.new(1, 1, ChunkyPNG::Color::WHITE) }
    it 'should read a stream without failing' do
      frame = ChunkyPNG::Frame.from_canvas(canvas, delay_num: 1, delay_den: 10)
      expect(frame).to be_instance_of ChunkyPNG::Frame
      expect(frame.width).to eql 1
      expect(frame.height).to eql 1
      expect(frame.delay_num).to eql 1
      expect(frame.delay_den).to eql 10
    end
  end

  describe '.from_chunks' do
    subject { ChunkyPNG::Frame.from_chunks(fctl_chunks, fdat_chunks, ds) }

    let(:ds) do
      filename = resource_file('2x2_loop_animation.png')
      ChunkyPNG::AnimationDatastream.from_file(filename)
    end

    context 'initial frame (default image)' do
      let(:fctl_chunks) { ds.frame_control_chunks.find { |c| c.sequence_number == 0 } }
      let(:fdat_chunks) { [] }
      it 'should read a stream without failing' do
        is_expected.to be_instance_of ChunkyPNG::Frame
        expect(subject.width).to eql 2
        expect(subject.height).to eql 2
        expect(subject.delay_num).to eql 1
        expect(subject.delay_den).to eql 30
        expect(subject.pixels).to eql [0, 0, 0, 0]
      end
    end

    context 'second frame' do
      let(:fctl_chunks) { ds.frame_control_chunks.find { |c| c.sequence_number == 1 } }
      let(:fdat_chunks) { ds.frame_data_chunks.select { |c| c.sequence_number == 2 } }
      it 'should read a stream without failing' do
        is_expected.to be_instance_of ChunkyPNG::Frame
        expect(subject.width).to eql 1
        expect(subject.height).to eql 2
        expect(subject.delay_num).to eql 1
        expect(subject.delay_den).to eql 30
      end
    end
  end

  describe '#to_frame_control_chunk' do
    subject { frame.to_frame_control_chunk(5) }
    let(:frame) { ChunkyPNG::Frame.new(1, 1, ChunkyPNG::Color::WHITE, attrs) }
    let(:attrs) { { delay_num: 1, delay_den: 30 } }
    it do
      is_expected.to be_instance_of ChunkyPNG::Chunk::FrameControl
      expect(subject.sequence_number).to eql 5
      expect(subject.width).to eql 1
      expect(subject.height).to eql 1
      expect(subject.delay_num).to eql 1
      expect(subject.delay_den).to eql 30
    end
  end

  describe '#to_frame_data_chunk' do
    subject { frame.to_frame_data_chunk }
    let(:frame) { ChunkyPNG::Frame.new(1, 1, ChunkyPNG::Color::WHITE, attrs) }
    let(:attrs) { { delay_num: 1, delay_den: 30 } }
    it do
      is_expected.to be_instance_of Array
      expect(subject.size).to eql 1
      expect(subject.first).to be_instance_of ChunkyPNG::Chunk::FrameData
    end
  end
end
