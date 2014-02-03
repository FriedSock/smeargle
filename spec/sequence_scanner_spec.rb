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

end
