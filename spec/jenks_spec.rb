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

  it 'should work when the data is unsorted' do
    data = [1,1,1,1,2,2,2,2,2,2,2,2,1,1,1]
    result = Jenks.cluster data, 2
    result.should == [[1,1,1,1,1,1,1],[2,2,2,2,2,2,2,2]]
  end

  it 'should not affect the original data' do
    data = [1,3,7,2]
    Jenks.cluster data, 2
    data.should == [1,3,7,2]
  end

  it 'works' do
    data = [1,1,2,100]
    result = Jenks.linear_cluster data, 3
    result.should == [[1,1,2], [100]]
  end

  it 'will return the same number of values that it started with' do
    data = [1393370173,1393370173,1393370173,1393370173,1393278229,1393278229,
            1393278229,1393278229,1393278229,1393370173,1393278229,1393278229,
            1393278229,1393278229,1393278229,1393278229,1393278229,1393278229,
            1393278229,1393278229,1393278229,1393278229,1393694355,1393278229,
            1393370173,1393278229,1393278229,1393370173,1393370173,1393370173,
            1393370173,1393370173,1393370173,1393278229,1393278229,1393278229,
            1393694355,1393278229,1393278229,1393694355,1393694355,1393694355,
            1393694355,1393694355,1393278229]
    result = Jenks.cluster data, 6
    puts result[0]
    puts ""
    puts result[1]
    puts ""
    puts result[2]
    result.map{|c| c.length}.reduce(:+).should == data.length
  end

end
