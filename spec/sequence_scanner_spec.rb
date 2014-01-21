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

    @scanner = SequenceScanner.new @filename
  end

  it 'Detects some consecutive identical lines' do
    File.should_receive(:open).with(@filename, 'r').and_return @lines_of_file
    @scanner.ranges.should == [[3,4]]
  end

  it 'Should work when the last line of the file is in a sequence' do
    lines_of_file = @lines_of_file
    lines_of_file += [ 'This line is not unique\n',
                       'This line is not unique\n',
                       'This line is not unique\n',
                       'c-c-c-c-c-combo breaker\n',
                       'This line is not unique\n',
                       'This line is not unique\n' ]
    File.should_receive(:open).with(@filename, 'r').and_return lines_of_file
    @scanner.ranges.should == [ [3,4], [6,8], [10,11] ]
  end


end
