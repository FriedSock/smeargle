require 'plugin/sign.rb'
require 'rspec'
require 'ruby-debug'

describe Sign do

  before do
    VIM = double
    line = 3
    hlgroup = 'Groop'
    @sign = Sign.new line, hlgroup
  end

  describe 'move down' do
    it 'increments line' do
      @sign.move_down
      @sign.line.should == 4
    end
  end

  describe 'move up' do
    it 'increments line' do
      @sign.move_up
      @sign.line.should == 2
    end
  end

end
