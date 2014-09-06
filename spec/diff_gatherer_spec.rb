require File.expand_path(File.join(File.dirname(__FILE__), '..','plugin','diff_gatherer.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

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
      @diff_gatherer.git_diff.should == {:additions => [{:original_line => 5, :new_line => 5, :content => '' },
                                                    {:original_line => 6, :new_line => 6, :content => '' },
                                                    {:original_line => 8, :new_line => 8, :content => 'Oh yeah'}],
                                         :deletions => [],
                                         :plus_regions => [[5,6]]}
    end

    it 'works for deletions' do
      file_content = ['I am line 1',
                      '',
                      '',
                      'Something else',
                      'I am someone else']

      stub_file_content 'file2', file_content
      @diff_gatherer.git_diff.should == {:additions => [],
                                         :deletions => [{:original_line => 2, :new_line => 2, :content => 'I am line 2'}],
                                         :plus_regions => []}
    end

    it 'with a change compression' do
      file_content = ['I am',
                      '',
                      '',
                      'Smething else',
                      'I am someone else',
                      'The best arddoun']

      stub_file_content 'file2', file_content
      @diff_gatherer.git_diff.should == {:additions => [ {:original_line => 1, :new_line => 1, :content => 'I am'},
                                                         {:original_line => 4, :new_line => 4, :content => 'Smething else'},
                                                         {:original_line => 6, :new_line => 6, :content => 'The best arddoun'}],
                                         :deletions => [  {:original_line => 1, :new_line => 1, :content => 'I am line 1'},
                                                          {:original_line => 2, :new_line => 2, :content => 'I am line 2'},
                                                          {:original_line => 5, :new_line => 5, :content => 'Something else'}],
                                         :plus_regions => []}
    end
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
