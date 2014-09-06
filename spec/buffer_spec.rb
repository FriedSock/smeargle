require File.expand_path(File.join(File.dirname(__FILE__), '..','plugin','buffer.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe Buffer do

  before do
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

    line_colourer = double
    line_colourer.stub(:get_colour) {|c| 'colour'}
    LineColourer.should_receive(:new) { line_colourer }
    @buffer = Buffer.new filename
    @buffer.stub(:get_new_id) { 1 }

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
    `rm temp-Necrophile` if File.exists? 'temp-Necrophile'
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

    it 'Places a sign from the right group' do
      line_number = 1
      hl = 'John'
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
      pending
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

  describe 'consider_last_changes' do

    it 'Can detect which lines have been deleted' do
      new_file_content = ['I am line 1',
                          'I am line 2',
                          '',
                          'Something else']

      stub_temp_file new_file_content
      deleted_lines= [{:original_line => 4, :new_line => 4, :content =>""}, {:original_line => 6, :new_line => 6, :content=>"I am someone else"}]
      @buffer.should_receive(:handle_deleted_lines).with deleted_lines
      @buffer.should_receive(:handle_added_lines).with []
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
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
      @buffer.should_receive(:handle_added_lines).with [{:original_line => 5, :new_line => 5, :content=>'', :type => :add}]
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
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
      @buffer.should_receive(:handle_deleted_lines).with [{:content=>"", :original_line => 4, :new_line => 4},
                                                          {:content=>"Something else", :original_line => 5, :new_line => 5},
                                                          {:content=>"I am someone else", :original_line => 6, :new_line => 6}]
      @buffer.should_receive(:handle_added_lines).with [{:original_line => 4, :new_line => 4, :content => 'Gonna make a change', :type => :add},
                                                        {:original_line => 5, :new_line => 5, :content => 'Gonna make a difference', :type => :add},
                                                        {:original_line => 6, :new_line => 6,:content => 'Gonna make it riiiiiiight', :type => :add}]
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with []
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
      @buffer.should_receive(:handle_undeleted_lines).with [{:original_line => 4, :new_line => 4, :content =>''},
                                                            {:original_line => 6, :new_line => 6, :content =>'I am someone else'}]
      @buffer.should_receive(:handle_unadded_lines).with []
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
      @buffer.should_receive(:handle_undeleted_lines).with []
      @buffer.should_receive(:handle_unadded_lines).with [{:original_line => 5, :new_line => 5, :content => ''}]
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
      @buffer.should_receive(:handle_unadded_lines).with [{:content => 'Gonna make a change', :original_line => 4, :new_line => 4},
                                                          {:content =>'Gonna make a difference', :original_line => 5, :new_line => 5},
                                                          {:content => 'Gonna make it riiiiiiight', :original_line => 6, :new_line => 6}]
      @buffer.should_receive(:handle_undeleted_lines).with [{:content=>"", :original_line => 4, :new_line => 4},
                                                            {:content=>"Something else", :original_line => 5, :new_line => 5},
                                                            {:content=>"I am someone else", :original_line => 6, :new_line => 6}]
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
