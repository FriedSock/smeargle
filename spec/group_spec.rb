require 'plugin/group.rb'
require 'rspec'
require 'ruby-debug'

describe Group do

  before do
    VIM = double
    name = 'Name'
    hlgroup = 'Groop'
    command = 'sign define Name linehl=Groop'
    VIM.should_receive(:command).with command
    @group = Group.new name, hlgroup
  end

  it 'should have accessors' do
    @group.name.should == 'Name'
    @group.highlight_group.should == 'Groop'
  end

  describe 'add_sign' do
    it 'adds an id' do
      @group.add_sign 10
      @group.ids.include?(10).should be_true
    end

    it 'should return nil if the id already exists' do
      @group.add_sign 10
      @group.add_sign(10).should be_nil
    end
  end

  describe 'remove_sign' do
    before do
      @group.add_sign 10
    end

    it 'removes an id' do
      @group.remove_sign 10
      @group.ids.include?(10).should be_false
    end

    it 'should return nil if the id is not present' do
      @group.remove_sign(111).should be_nil
    end
  end

end
