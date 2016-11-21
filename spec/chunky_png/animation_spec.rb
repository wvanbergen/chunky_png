require 'spec_helper'

describe ChunkyPNG::Animation do
  describe '#initialize' do
    it 'should use a transparent background by default' do
      animation = ChunkyPNG::Animation.new(1, 1)
      expect(animation[0,0]).to eql ChunkyPNG::Color::TRANSPARENT
    end

    it 'should accept initial pixel values' do
      animation = ChunkyPNG::Animation.new(2, 2, [1,2,3,4])
      expect(animation[0, 0]).to eql 1
      expect(animation[1, 0]).to eql 2
      expect(animation[0, 1]).to eql 3
      expect(animation[1, 1]).to eql 4
    end

    it 'should not accept pixel values as frame data by default' do
      animation = ChunkyPNG::Animation.new(1, 1, 'red @ 0.8')
      expect(animation.default_image_is_first_frame).to eql false
      expect(animation.frames).to be_empty
    end

    it 'should accept pixel values as first frame data with `first_frame` flag' do
      animation = ChunkyPNG::Animation.new(1, 1, 'red @ 0.8', true)
      expect(animation.default_image_is_first_frame).to eql true
      expect(animation.frames.size).to eql 1
      expect(animation.frames.first).to be_instance_of ChunkyPNG::Frame
    end
  end

  describe '.from_frame' do
    it 'should accept instance of ChunkyPNG::Frame as a first frame' do
      frame = ChunkyPNG::Frame.new(1, 2, [1,2])
      animation = ChunkyPNG::Animation.from_frame(frame)
      expect(animation.width).to eql 1
      expect(animation.height).to eql 2
      expect(animation.pixels).to eql [1,2]
      expect(animation.default_image_is_first_frame).to eql true
      expect(animation.frames.size).to eql 1
      expect(animation.frames.first).to eql frame
    end
  end

  describe '#num_frames' do
    subject { animation.num_frames }
    let(:animation) do
      ChunkyPNG::Animation.new(1, 1, ChunkyPNG::Color::WHITE, false).tap do |a|
        3.times { a.frames << ChunkyPNG::Frame.new(1, 1, ChunkyPNG::Color::WHITE) }
      end
    end

    it 'should executes #size method of `@frames`' do
      expect(animation.frames).to receive(:size).and_call_original
      is_expected.to eql 3
    end
  end

  describe '.from_file' do
    context 'load apng file' do
      it 'should read a stream without failing' do
        filename = resource_file('2x2_loop_animation.png')
        animation = ChunkyPNG::Animation.from_file(filename)
        expect(animation).to be_instance_of ChunkyPNG::Animation
        expect(animation.num_frames).to eql 4
        expect(animation.num_plays).to eql 0
        expect(animation.default_image_is_first_frame).to eql true
      end
    end

    context 'load not animated png file' do
      it 'should read a stream without failing' do
        filename = resource_file('clock.png')
        animation = ChunkyPNG::Animation.from_file(filename)
        expect(animation).to be_instance_of ChunkyPNG::Animation
        expect(animation.num_frames).to eql 0
        expect(animation.num_plays).to eql 0
        expect(animation.default_image_is_first_frame).to eql false
      end
    end
  end

  describe '#to_datastream' do
    subject { animation.to_datastream }
    let(:animation) do
      ChunkyPNG::Animation.new(1, 1, ChunkyPNG::Color::WHITE, true).tap do |a|
        4.times { a.frames << ChunkyPNG::Frame.new(1, 1, ChunkyPNG::Color::WHITE) }
      end
    end
    it 'should return animation datastream' do
      expect(subject).to be_instance_of ChunkyPNG::AnimationDatastream
      expect(subject.animation_control_chunk)
        .to be_instance_of ChunkyPNG::Chunk::AnimationControl
      expect(subject.frame_control_chunks.size).to eql 5
      expect(subject.frame_data_chunks.size).to eql 4
      expect(subject.frame_control_chunks.first)
        .to be_instance_of ChunkyPNG::Chunk::FrameControl
      expect(subject.frame_data_chunks.first)
        .to be_instance_of ChunkyPNG::Chunk::FrameData
    end
  end
end
