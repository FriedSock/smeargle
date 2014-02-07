require File.join(File.dirname(__FILE__), 'group.rb')
require File.join(File.dirname(__FILE__), 'sign.rb')

class Buffer

  attr_accessor :sequence_scanner

  def initialize filename
    @filename = filename
    @sequence_scanner = SequenceScanner.new(filename)
    @_id = 0
    @last_deleted_lines = []
    @last_added_lines = []
    @last_changed_lines = []
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
    return nil if !sign

    VIM::command "sign unplace #{id}"
    groups[sign.group].remove_sign id
    signs.delete id
  end

  #Move down all signs below the specified line, we are essentially
  #inserting a line at this point
  def move_signs_down original_line
    line = original_line_to_line original_line
    signs.each do |id, s|
      if s.line >= line
        s.move_down
      end
    end
  end

  #Remove line - all lines below the deleted line will be moved up
  def move_signs_up original_line
    line = original_line_to_line original_line
    signs.each do |id, s|
      if s.line > line
        s.move_up
      end
    end
  end

  def reinstate_sign original_line
    id, sign = signs.detect { |k,v| v.original_line == original_line }
    sign.move_up
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
    added_lines = []
    changed_lines = []
    deleted_lines = []

    get_diff.split(' ').each do |str|
      break if '<>-'.include? str[0]

      if str.include? 'a'
        range = str.split('a')[1..-1]
      elsif str.include? 'c'
        range = str.split('c')[1..-1]
      elsif str.include? 'd'
        range = str.split('d')[0..-2]
      end

      range.each do |s|
        r = extract_range(s)
        if str.include? 'a'
          r.each do |n| added_lines << n end
        elsif str.include? 'c'
          r.each do |n| changed_lines << n end
        elsif str.include? 'd'
          r.each do |n| deleted_lines << n end
        end
      end
    end

    lines_that_have_been_deleted = deleted_lines - @last_deleted_lines
    lines_that_have_been_undeleted = @last_deleted_lines - deleted_lines

    lines_that_have_changed = changed_lines - @last_changed_lines
    lines_that_have_unchanged = @last_changed_lines - changed_lines

    lines_that_have_been_added = added_lines - @last_added_lines
    lines_that_have_been_unadded = @last_added_lines - added_lines

    handle_deleted_lines lines_that_have_been_deleted
    handle_added_lines lines_that_have_been_added
    handle_changed_lines lines_that_have_changed
    handle_undeleted_lines lines_that_have_been_undeleted
    handle_unadded_lines lines_that_have_been_unadded
    handle_unchanged_lines lines_that_have_unchanged

    @last_added_lines = added_lines
    @last_changed_lines = changed_lines
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
      place_sign line, 'new'
    end
  end

  def handle_changed_lines lines
    return if lines.length == 0
    lines.each do |line|
      move_signs_down line
      place_sign line, 'new'
    end
  end

  def handle_undeleted_lines lines
    return if lines.length == 0
    lines.each do |line|
      move_signs_down line
      reinstate_sign line
    end
  end

  def handle_unadded_lines lines
    #TODO
  end

  def handle_unchanged_lines lines
    #TODO
  end

  def extract_range str
    if str.include? ','
      Range.new *str.split(',').map(&:to_i)
    else
      Range.new *[str.to_i]*2
    end
  end

  def get_diff
    `diff #{@filename} #{temp_filename} | sed '/^[<|>|-]/ d' | tr '\n' ' '`
  end

  def temp_filename
    '/tmp/' + @filename.sub('/', '') + 'funny'
  end

end
