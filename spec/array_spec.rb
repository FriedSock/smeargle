require 'plugin/array.rb'
require 'rspec'
require 'ruby-debug'

describe "Helper Methods" do

  it 'works for an empty array' do
    [].to_s.should == '[]'
  end

  it 'works for others, too' do
    [1,2,3].to_s.should == '[1,2,3]'
  end

  it 'works for embedding' do
    "#{[1,2]}".should == '[1,2]'
  end

end
