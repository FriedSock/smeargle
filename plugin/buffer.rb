require File.join(File.dirname(__FILE__), 'group.rb')
require File.join(File.dirname(__FILE__), 'sign.rb')
require File.join(File.dirname(__FILE__), 'diff_gatherer.rb')

class Buffer

  attr_accessor :sequence_scanner

  def initialize filename
    @filename = filename
    @sequence_scanner = SequenceScanner.new(filename)
    @_id = 0
    @last_deleted_lines = []
    @last_added_lines = []
  end

  def groups
    @_groups ||= {}
  end

  def signs
    @_signs ||= {}
  end

  def get_new_id
    @_id += 1
    @_id
  end

  def find_current_sequence line
    @sequence_scanner.current_sequence line
  end

  def find_extending_sequence line, content
    @sequence_scanner.extending_sequence line, content
  end

  def define_sign name, hlgroup
    group = Group.new name, hlgroup
    groups[name] = group
  end

  def place_sign line_no, hl
    id = get_new_id
    VIM.command "sign place #{id} name=#{hl} line=#{line_no} file=#{@filename}"
    groups[hl].add_sign id
    signs[id] = Sign.new line_no, hl
  end

  #Unplaces a "new" sign
  def unplace_sign line_no
    id, sign = signs.detect { |k,v| v.line == line_no && v.group == 'new' }
    return if !sign
    VIM::command "sign unplace #{id}"
    groups[sign.group].remove_sign id
    signs.delete id
  end

  #Move down all signs below the specified line, we are essentially
  #inserting a line at this point
  def move_signs_down line_hash
    original_line = line_hash[:line]
    content = line_hash[:content]

    line = original_line_to_line original_line

    #Trying to move down the last line in the file
    return if !line

    if seq = find_current_sequence(line)
      #puts "START:" + seq.start
    elsif seq = find_extending_sequence(line, content)
      #puts "Extending " + seq.start
    else
      #TODO
    end
    signs.each do |id, s|
      if !line
        puts "line #{line_hash}"
      end
      if s.line >= line
        s.move_down
      end
    end
  end

  #Remove line - all lines below the deleted line will be moved up
  def move_signs_up line_hash
    original_line = line_hash[:line]

    line = original_line_to_line original_line
    line = line_hash[:line] if !line

    signs.each do |id, s|
      if s.line > line
        s.move_up
      end
    end
  end

  def reinstate_sign line_hash, *flags
    original_line = line_hash[:line]
    id, sign = signs.detect { |k,v| v.original_line == original_line }
    sign.move_up if flags.include? :move_up
    VIM.command "sign place #{id} name=#{sign.group} line=#{sign.line} file=#{@filename}"
  end

  def original_line_to_line original_line
    id, sign = signs.detect { |k,v| v.original_line == original_line }
    sign ? sign.line : nil
  end

  def get_line_content line
    return nil if line < 1
    id, sign = signs.detect { |k,v| v.line == line }
    sign ? sign.line_content : nil
  end

  def consider_last_change
    diff = get_diff

    deleted_lines = diff[:deletions]
    added_lines = diff[:additions]

    lines_that_have_been_deleted = deleted_lines.select{ |l| !@last_deleted_lines.detect {|n| n[:line] == l[:line]} }
    lines_that_have_been_undeleted = @last_deleted_lines.select{ |l| !deleted_lines.detect {|n| n[:line] == l[:line]} }

    lines_that_have_been_added = added_lines.select{ |l| !@last_added_lines.detect {|n| n[:line] == l[:line]} }
    lines_that_have_been_unadded = @last_added_lines.select{ |l| !added_lines.detect {|n| n[:line] == l[:line]} }

    #puts "added_lines: #{added_lines}"
    #puts "last_added_lines: #{@last_added_lines}"
    #puts "lines_that_have_been_added: #{lines_that_have_been_added}"
    #puts "lines_that_have_unadded: #{lines_that_have_been_unadded}"

    handle_deleted_lines lines_that_have_been_deleted
    handle_added_lines lines_that_have_been_added
    handle_undeleted_lines lines_that_have_been_undeleted
    handle_unadded_lines lines_that_have_been_unadded

    @last_added_lines = added_lines
    @last_deleted_lines = deleted_lines
  end

  def handle_deleted_lines lines
    return if lines.length == 0
    lines.each do |line|
      move_signs_up line
    end
  end

  def handle_added_lines lines
    return if lines.length == 0
    lines.each do |line|
      move_signs_down line
      place_sign line[:line], 'new'
    end
  end

  def handle_undeleted_lines lines
    return if lines.length == 0
    lines.each do |line|
      move_signs_down line
      reinstate_sign line, :move_up
    end
  end

  def handle_unadded_lines lines
    return if lines.length == 0
    lines.each do |line|
      unplace_sign line[:line]
      move_signs_up line
    end
  end

  def extract_range str
    if str.include? ','
      Range.new *str.split(',').map(&:to_i)
    else
      Range.new *[str.to_i]*2
    end
  end

  def get_diff
    diff_gatherer.git_diff
  end

  def diff_gatherer
    @_diff_gatherer ||= DiffGatherer.new @filename, temp_filename
  end

  def temp_filename
    '/tmp/' + @filename.sub('/', '') + 'funny'
  end

end
