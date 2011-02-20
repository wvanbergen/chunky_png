require 'spec_helper'

describe ChunkyPNG::Path do
  subject { ChunkyPNG::Path.new([]) }

  it { should respond_to(:points) }
  it { should have(0).points }

end
