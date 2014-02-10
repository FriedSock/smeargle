require 'plugin/buffer.rb'
require 'plugin/sequence_scanner.rb'
require 'rspec'
require 'ruby-debug'

describe Buffer do

  before do
    VIM = double
    filename = 'Necrophile'
    sequence_scanner = double
    SequenceScanner.should_receive(:new).with(filename) { sequence_scanner }
    @buffer = Buffer.new filename
  end

  describe 'define sign' do
    it 'Creates a new group' do
      name = 'John'
      hlname = 'Candy'
      Group.should_receive(:new).with(name, hlname)
      @buffer.define_sign name, hlname
    end
  end

  describe 'place sign' do
    before do
      group = double
      groups = { 'John' => group }
      group.should_receive(:add_sign).with(1)
      @buffer.should_receive(:groups) { groups }
    end

    it 'Places a sign from the right group' do
      line_number = 1
      hl = 'John'
      filename = 'Necrophile'
      command1 = "sign place 1 name=John line=1 file=Necrophile"
      VIM.should_receive(:command).with command1
      @buffer.place_sign line_number, hl
    end

    it 'Adds the sign to "Signs"' do
      signs = {}
      @buffer.should_receive(:signs) { signs }
      VIM.should_receive(:command).with 'sign place 1 name=John line=1 file=Necrophile'
      @buffer.place_sign 1, 'John'
      signs.size.should == 1
      sign = signs[1]
      sign.line.should == 1
      sign.original_line.should == 1
      sign.group.should == 'John'
    end
  end

  describe 'unplace sign' do
    before do
      group = double
      groups = { 'new' => group }
      group.should_receive(:remove_sign).with(1)
      @buffer.should_receive(:groups) { groups }
      sign = double
      signs = { 1 => sign }
      sign.should_receive(:line) { 1 }
      sign.should_receive(:group).twice { 'new' }
      @buffer.should_receive(:signs).twice { signs }
    end

    it 'Unplaces the right sign' do
      VIM.should_receive(:command).with 'sign unplace 1'
      @buffer.unplace_sign 1
    end
  end

  describe 'find by original line' do
    it 'finds by original line' do
      sign = double
      signs = { 1 => sign }
      sign.should_receive(:original_line) { 1 }
      sign.should_receive(:line) { 500 }
      @buffer.should_receive(:signs) { signs }
      @buffer.original_line_to_line(1).should == 500
    end
  end

  describe 'get_line_content' do
    before do
      @sign1 = double
      @sign1.stub(:line) { 1 }
      @sign2 = double
      @sign2.stub(:line) { 2 }
      @sign3 = double
      @sign3.stub(:line) { 3 }
      @signs = { 1 => @sign1, 2 => @sign2, 3 => @sign3 }
      @buffer.should_receive(:signs) { @signs }
    end

    it 'will find the right line if it exists, and return its content' do
      @sign2.should_receive(:line_content) { '^___^' }
      @buffer.get_line_content(2).should == '^___^'
    end

    it 'returns nil if the line is out of range' do
      @buffer.get_line_content(0).should be_nil
      @buffer.get_line_content(4).should be_nil
    end
  end


  describe 'move signs down' do
    pending
  end

  describe 'move signs up' do
    pending
  end

  describe 'consider_last_changes' do
    before do
      VIM.stub(:evaluate)
      VIM.stub(:command)
      filename = 'Necrophile'
      file_content = ['I am line 1',
                      'I am line 2',
                      '',
                      '',
                      'Something else',
                      'I am someone else']

      File.open('Necrophile', 'w') do |file|
        file_content.each do |line|
          file.puts line
        end
      end

      @buffer.define_sign 'Old', 'Oldgroup'
      @buffer.define_sign 'New', 'Newgroup'
      @buffer.define_sign 'new', 'new'
      @buffer.place_sign 1, 'Old'
      @buffer.place_sign 2, 'Old'
      @buffer.place_sign 3, 'Old'
      @buffer.place_sign 4, 'New'
      @buffer.place_sign 5, 'Old'
      @buffer.place_sign 6, 'Old'
      @buffer.place_sign 7, 'Old'

      @buffer.stub(:temp_filename) { 'temp-Necrophile' }
      @buffer.stub(:find_current_sequence)
      @buffer.stub(:find_extending_sequence)
    end

    after do
      `rm Necrophile`
      `rm temp-Necrophile`
    end

    it 'Can detect which lines have been deleted' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          'Something else']

      stub_temp_file new_file_content
      deleted_lines= [{:line => 4, :content =>""}, {:line => 6, :content=>"I am someone else"}]
      @buffer.should_receive(:handle_deleted_lines).with deleted_lines
      @buffer.should_receive(:handle_added_lines).with []
      @buffer.should_receive(:handle_changed_lines).with []
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
      @buffer.should_receive(:handle_unchanged_lines).with []
      @buffer.consider_last_change
    end

    it 'Can detext which lines have been added' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          '',
                          '',
                          'Something else',
                          'I am someone else']

      stub_temp_file new_file_content
      @buffer.should_receive(:handle_deleted_lines).with []
      @buffer.should_receive(:handle_added_lines).with [{:line=>5, :content=>''}]
      @buffer.should_receive(:handle_changed_lines).with []
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
      @buffer.should_receive(:handle_unchanged_lines).with []
      @buffer.consider_last_change
    end

    it 'Can detext which lines have been changed' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          'Gonna make a change',
                          'Gonna make a difference',
                          'Gonna make it riiiiiiight']

      stub_temp_file new_file_content
      @buffer.should_receive(:handle_deleted_lines).with []
      @buffer.should_receive(:handle_added_lines).with []
      @buffer.should_receive(:handle_changed_lines).with [{:line => 4, :content => 'Gonna make a change'},
                                                          {:line => 5, :content => 'Gonna make a difference'},
                                                          {:line => 6,:content => 'Gonna make it riiiiiiight'}]
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
      @buffer.should_receive(:handle_unchanged_lines).with []
      @buffer.consider_last_change
    end

    it 'Can detect undeleted lines' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          'Something else']
      stub_temp_file new_file_content
      @buffer.consider_last_change

      next_new_file_content = ['I am line 1',
                               'I am line 2',
                               '',
                               '',
                               'Something else',
                               'I am someone else']
      stub_temp_file next_new_file_content
      @buffer.should_receive(:handle_deleted_lines).with []
      @buffer.should_receive(:handle_added_lines).with []
      @buffer.should_receive(:handle_changed_lines).with []
      @buffer.should_receive(:handle_undeleted_lines).with [{:line => 4, :content =>''},
                                                            {:line => 6, :content =>'I am someone else'}]
      @buffer.should_receive(:handle_unadded_lines).with []
      @buffer.should_receive(:handle_unchanged_lines).with []
      @buffer.consider_last_change
    end

    it 'Can detect unadded lines' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          '',
                          '',
                          'Something else',
                          'I am someone else']
      stub_temp_file new_file_content
      @buffer.consider_last_change

      next_new_file_content = ['I am line 1',
                               'I am line 2',
                               '',
                               '',
                               'Something else',
                               'I am someone else']
      stub_temp_file next_new_file_content

      @buffer.should_receive(:handle_deleted_lines).with []
      @buffer.should_receive(:handle_added_lines).with []
      @buffer.should_receive(:handle_changed_lines).with []
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with [{:line =>5, :content => ''}]
      @buffer.should_receive(:handle_unchanged_lines).with []
      @buffer.consider_last_change
    end

    it 'Can detect unchanged lines' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          'Gonna make a change',
                          'Gonna make a difference',
                          'Gonna make it riiiiiiight']
      stub_temp_file new_file_content
      @buffer.consider_last_change

      next_new_file_content = ['I am line 1',
                               'I am line 2',
                               '',
                               '',
                               'Something else',
                               'I am someone else']
      stub_temp_file next_new_file_content

      @buffer.should_receive(:handle_deleted_lines).with []
      @buffer.should_receive(:handle_added_lines).with []
      @buffer.should_receive(:handle_changed_lines).with []
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
      @buffer.should_receive(:handle_unchanged_lines).with [{:content => 'Gonna make a change', :line => 4},
                                                            {:content =>'Gonna make a difference', :line => 5},
                                                            {:content => 'Gonna make it riiiiiiight', :line =>6}]
      @buffer.consider_last_change
    end
  end

end

def stub_temp_file arr
  File.open('temp-Necrophile', 'w') do |file|
    arr.each do |line|
      file.puts line
    end
  end
end
