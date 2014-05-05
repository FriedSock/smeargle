require 'plugin/diff_gatherer.rb'
require 'plugin/mapper.rb'
require 'rspec'
require 'ruby-debug'

describe Mapper do
  before do
    file1 = 'file1'
    file_content = ['I am line 1',
                    'I am line 2',
                    '',
                    '',
                    'Something else',
                    'I am someone else']

    File.open('file1', 'w') do |file|
      file_content.each do |line|
        file.puts line
      end
    end

    @diff_gatherer = DiffGatherer.new 'file1', 'file2'
  end

  it 'works for one addition' do
    file_content = ['I am line 1',
                    'I am line 2',
                    'nice line',
                    '',
                    '',
                    'Something else',
                    'I am someone else']

    stub_file_content 'file2', file_content
    mapper = Mapper.new @diff_gatherer.git_diff[:additions], @diff_gatherer.git_diff[:deletions]
    mapper.map(1).should == 1
    mapper.map(5).should == 6
  end


  it 'works' do
    file_content = ['I am',
                    '',
                    '',
                    'Smething else',
                    'I am someone else',
                    'The best arddoun']

    stub_file_content 'file2', file_content
    mapper = Mapper.new @diff_gatherer.git_diff[:additions], @diff_gatherer.git_diff[:deletions]
    mapper.map(6).should == 5
  end

  it 'return nil when the line is gone' do
    file_content = ['I am',
                    'I am line 2',
                    'nice line',
                    'Smething else',
                    'I am someone else',
                    'The best arddoun']

    stub_file_content 'file2', file_content
    mapper = Mapper.new @diff_gatherer.git_diff[:additions], @diff_gatherer.git_diff[:deletions]
    mapper.map(1).should == nil
    mapper.map(6).should == 5
  end

  it 'works when there are no changes' do
    file_content = ['I am line 1',
                    'I am line 2',
                    '',
                    '',
                    'Something else',
                    'I am someone else']

    stub_file_content 'file2', file_content
    mapper = Mapper.new @diff_gatherer.git_diff[:additions], @diff_gatherer.git_diff[:deletions]
    mapper.map(1).should == 1
    mapper.map(2).should == 2
    mapper.map(6).should == 6
  end

  after :all do
    `rm file1`
    `rm file2`
  end

end

def stub_file_content filename, file_content
  File.open(filename, 'w') do |file|
    file_content.each do |line|
      file.puts line
    end
  end
end
