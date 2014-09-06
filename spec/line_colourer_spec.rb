require File.expand_path(File.join(File.dirname(__FILE__), '..', 'plugin','line_colourer.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe LineColourer do

  before do
    git_out_path = File.join(File.dirname(__FILE__), 'fixtures/git_blame.txt')
    git_out = File.open(git_out_path).read
    LineColourer.stub(:git_blame_output) { git_out }
    @line_colourer = LineColourer.new 'filename', 1
  end

  describe 'generate_authors' do

    #This example is based on a file from the jquery codebase, chosen because
    #it has many distinct authors, for more information see the test fixture.
    it 'works' do
      author_groups = [0, 1, 0, 5, 1, 5, 0, 0, 1, 1, 0, 0, 0, 4, 2, 1, 0, 0, 0,
                       1, 0, 1, 0, 1, 1, 1, 1, 1, 5, 1, 5, 1, 0, 1, 0, 0, 0, 1,
                       0, 0, 0, 1, 5, 5, 5, 5, 5, 0, 5, 1, 1, 1, 1, 1, 5, 5, 5,
                       0, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 2, 2, 0, 1, 0, 0,
                       0, 0, 0, 0, 5, 1, 3, 1, 0, 0, 0, 0, 0, 1, 0, 0, 3, 5, 3,
                       4, 3, 3, 3, 4, 3, 3, 3, 3, 3, 0, 1, 0, 1, 0, 0, 5, 5, 5,
                       5, 5, 4, 5, 5, 0, 1, 4, 0, 4, 3, 3, 3, 0, 0, 0, 0, 2, 0,
                       0, 0, 5, 2, 2, 2, 5, 2, 2, 2, 5, 2, 2, 2, 5, 2, 2, 2, 2,
                       5, 2, 2, 2, 1, 4, 2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 2, 2,
                       0, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1,
                       1, 1, 0, 0, 0, 5, 5, 5, 0, 0, 0, 1, 1, 1, 1, 5, 1, 5, 4,
                       5, 1, 0, 1]
      @line_colourer.generate_authors('filename').should == author_groups
    end
  end

end
