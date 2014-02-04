require 'plugin/sequence_scanner.rb'
require 'rspec'
require 'ruby-debug'

describe SequenceScanner do

  before do
    @filename = 'Peadofile'
    @lines_of_file = [ 'I am the first line\n',
                      'I am the second line\n',
                      '\n',
                      '\n',
                      'I am the last line \n' ]
    File.stub(:open).with(@filename, 'r').and_return @lines_of_file
    @scanner = SequenceScanner.new @filename
  end

  it 'Detects some consecutive identical lines' do
    @scanner.ranges.should == [[3,4, '\n']]
  end

  it 'Should work when the last line of the file is in a sequence' do
    lines_of_file = @lines_of_file
    lines_of_file += [ 'This line is not unique\n',
                       'This line is not unique\n',
                       'This line is not unique\n',
                       'c-c-c-c-c-combo breaker\n',
                       'This line is not unique\n',
                       'This line is not unique\n' ]
    File.stub(:open).with(@filename, 'r').and_return lines_of_file
    @scanner.ranges.map{ |t| t[0..-2]}.should == [ [3,4], [6,8], [10,11] ]
  end

  it 'Should be able to return sequence objects' do
    seq1, seq2, seq3 = *@scanner.sequences
    seq1.start.should == 3
    seq1.finish.should == 4
  end

  describe 'finding the current sequence' do
    it 'works' do
      seq1 = @scanner.current_sequence 3
      seq1.start.should == 3
      seq1.finish.should == 4
      seq1.content.should == '\n'
    end
  end

  describe 'making changes' do
    before do
      @lines_of_file = [ 'Part of a Sequence',
                         'Part of a Sequence',
                         'Not part of a Sequence',
                         'Part of a Sequence',
                         'Part of a Sequence',
                         'Part of a Sequence']
      File.stub(:open).with(@filename, 'r').and_return @lines_of_file
      @scanner = SequenceScanner.new @filename
    end

    describe 'additions' do
      it 'Will fragment a sequence if a different line is inserted' do
        p = 'Part of a Sequence'
        @scanner.notify_addition 5, 'Frag out', p, p
        seq1, seq2 = @scanner.sequences
        seq1.start.should == 1
        seq1.finish.should == 2
        seq2.start.should == 6
        seq2.finish.should == 7
      end

      it 'will increase the size of a sequence if the same content is inserted' do
        p = 'Part of a Sequence'
        @scanner.notify_addition 5, 'Part of a Sequence', p, p
        seq1, seq2 = @scanner.sequences
        seq1.start.should == 1
        seq1.finish.should == 2
        seq2.start.should == 4
        seq2.finish.should == 7
      end

      it 'will create a new sequence if an addition should create one' do
        p = 'Part of a Sequence'
        n = 'Not part of a Sequence'
        @scanner.notify_addition 3, 'Not part of a Sequence', p, n
        @scanner.sequences.length.should == 3
        seq1, seq2, seq3 = @scanner.sequences
        seq1.start.should == 1
        seq1.finish.should == 2
        seq2.start.should == 3
        seq2.finish.should == 4
        seq3.start.should == 5
        seq3.finish.should == 7
      end
    end

    describe 'deletions' do
      it 'Will coalesce two sequences if a dividing line is destroyed' do
        @scanner.notify_deletion 3
        @scanner.sequences.length.should == 1
        seq1 = @scanner.sequences.first
        seq1.start.should == 1
        seq1.finish.should == 5
      end

      it 'Will shrink a sequence if an internal is line deleted' do
        @scanner.notify_deletion 5
        seq1, seq2 = @scanner.sequences
        seq1.start.should == 1
        seq1.finish.should == 2
        seq2.start.should == 4
        seq2.finish.should == 5
      end
    end

  end

end
