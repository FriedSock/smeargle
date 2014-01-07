require 'plugin/jenks.rb'
require 'rspec'

describe Jenks do

  it 'should find class breaks' do
    data = [1,2,3,5,100,102,105]
    result = Jenks.get_breaks data, 2
    result.should == [5, 105]
  end

  it 'should be able to group data' do
    data = [1,2,3,5,100,102,105]
    result = Jenks.cluster data, 2
    result.should == [[1,2,3,5],[100,102,105]]
  end

  it 'should handle duplicates' do
    data = [1,1,1,1,2]
    result = Jenks.cluster data, 2
    result.should == [[1,1,1,1],[2]]
  end

  it 'should only return non-empty classes' do
    data = [1,1,1,1,2]
    result = Jenks.cluster data, 3
    result.should == [[1,1,1,1],[2]]
  end

end
