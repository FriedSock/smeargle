require 'plugin/diff_gatherer.rb'
require 'rspec'
require 'ruby-debug'

describe DiffGatherer do

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

  describe 'diff' do

    it 'works for additions' do
      file_content = ['I am line 1',
                      'I am line 2',
                      '',
                      '',
                      '',
                      '',
                      'Something else',
                      'Oh yeah',
                      'I am someone else']

      stub_file_content 'file2', file_content
      @diff_gatherer.diff.should == {:additions => [{:line => 5, :content => '' },
                                                    {:line => 6, :content => '' },
                                                    {:line => 8, :content => 'Oh yeah'}],
      :deletions => [],
      :changes => []}
    end

    it 'works for deletions' do
      file_content = ['I am line 1',
                      '',
                      '',
                      'Something else',
                      'I am someone else']

      stub_file_content 'file2', file_content
      @diff_gatherer.diff.should == {:additions => [],
                                     :deletions => [{:line => 2, :content => 'I am line 2'}],
                                     :changes => []}
    end

    it 'works for changes' do
      file_content = ['I am lne 1',
                      'I am line 2',
                      '',
                      '',
                      'Smething else',
                      'I am someone else']

      stub_file_content 'file2', file_content
      @diff_gatherer.diff.should == {:additions => [],
                                     :deletions => [],
                                     :changes => [{:line => 1, :content => 'I am lne 1'},
                                                  {:line => 5, :content => 'Smething else'}]}
    end

    it 'with a change compression' do
      file_content = ['I am',
                      '',
                      '',
                      'Smething else',
                      'I am someone else',
                      'The best arddoun']

      stub_file_content 'file2', file_content
      @diff_gatherer.diff.should == {:additions => [{:line => 6, :content => 'The best arddoun'}],
                                     :deletions => [{:line => 2, :content => nil}],
                                     :changes => [{:line => 1, :content => 'I am'},
                                                  {:line => 4, :content => 'Smething else'}]}
    end
  end

  describe 'git_diff' do
    it 'works for additions' do
      file_content = ['I am line 1',
                      'I am line 2',
                      '',
                      '',
                      '',
                      '',
                      'Something else',
                      'Oh yeah',
                      'I am someone else']

      stub_file_content 'file2', file_content
      @diff_gatherer.git_diff.should == {:additions => [{:line => 5, :content => '' },
                                                    {:line => 6, :content => '' },
                                                    {:line => 8, :content => 'Oh yeah'}],
      :deletions => []}
    end

    it 'works for deletions' do
      file_content = ['I am line 1',
                      '',
                      '',
                      'Something else',
                      'I am someone else']

      stub_file_content 'file2', file_content
      @diff_gatherer.git_diff.should == {:additions => [],
                                         :deletions => [{:line => 2, :content => 'I am line 2'}]}
    end

    it 'with a change compression' do
      file_content = ['I am',
                      '',
                      '',
                      'Smething else',
                      'I am someone else',
                      'The best arddoun']

      stub_file_content 'file2', file_content
      @diff_gatherer.git_diff.should == {:additions => [ {:line => 1, :content => 'I am'},
                                                         {:line => 4, :content => 'Smething else'},
                                                         {:line => 6, :content => 'The best arddoun'}],
                                         :deletions => [  {:line => 1, :content => 'I am line 1'},
                                                          {:line => 2, :content => 'I am line 2'},
                                                          {:line => 4, :content => 'Something else'}]}
    end
  end


  after :all do
    #`rm file1`
    #`rm file2`
  end

end

def stub_file_content filename, file_content
  File.open(filename, 'w') do |file|
    file_content.each do |line|
      file.puts line
    end
  end
end
