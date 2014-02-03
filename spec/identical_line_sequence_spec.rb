require 'plugin/identical_line_sequence.rb'
require 'rspec'
require 'ruby-debug'

describe IdenticalLineSequence do

  before do
    @sequence = IdenticalLineSequence.new 2,6, ''
  end

  describe 'fragment' do

    it 'Can fragment, given a line number' do
      seq1, seq2 = @sequence.fragment 4
      seq1.start.should == 2
      seq1.finish.should == 3
      seq2.start.should == 5
      seq2.finish.should == 6
    end

    it 'Should only return one sequence if an outlying line is changed' do
      seq1, seq2 = @sequence.fragment 2
      seq1.should == nil
      seq2.start.should == 3
      seq2.finish.should == 6
    end

    it 'Returns 2 nils if a sequence gets destroyed' do
      small_seq = IdenticalLineSequence.new 1, 2, 'moo'
      seq1, seq2 = small_seq.fragment 1
      seq1.should be_nil
      seq2.should be_nil
    end

    it 'Returns 2 nils if a bigger sequence gets destroyed' do
      small_seq = IdenticalLineSequence.new 1, 3, 'moo'
      seq1, seq2 = small_seq.fragment 2
      seq1.should be_nil
      seq2.should be_nil
    end

    it 'Returns nils if the line fragment is out of bounds' do
      seq1, seq2 = @sequence.fragment 10
      seq1.should be_nil
      seq2.should be_nil
    end
  end

  describe 'moving' do

    it 'should decrement lines when moved up' do
      @sequence.move_up
      @sequence.start.should == 1
      @sequence.finish.should == 5
    end

    it 'should increment lines when moved up' do
      @sequence.move_down
      @sequence.start.should == 3
      @sequence.finish.should == 7
    end
  end


  describe 'contains_line?' do
    it 'works' do
      @sequence.contains_line?(3).should be_true
      @sequence.contains_line?(420).should be_false
    end
  end

  it 'can return itself as a range' do
    @sequence.range.should == (2..6)
  end

end
