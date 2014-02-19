require File.join(File.dirname(__FILE__), 'group.rb')
require File.join(File.dirname(__FILE__), 'sign.rb')
require File.join(File.dirname(__FILE__), 'diff_gatherer.rb')
require File.join(File.dirname(__FILE__), 'line_colourer.rb')

class Buffer

  def initialize filename
    @filename = filename
    ['col232', 'col233', 'col234', 'col235', 'col236', 'col237', 'col238', 'new'].each { |c| define_sign c, c }
    @line_colourer = LineColourer.new filename
    @last_deleted_lines = []
    @last_added_lines = []
    $id ||= 0
  end

  def highlight_lines opts={}
    @line_colourer.highlight_lines opts
  end

  def groups
    @_groups ||= {}
  end

  def signs
    @_signs ||= {}
  end

  def get_new_id
    $id += 1
    $id
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
  def unplace_sign id, sign
    return if !sign
    VIM::command "sign unplace #{id}"
    groups[sign.group].remove_sign id
    signs.delete id
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

    lines_that_have_been_deleted = deleted_lines.select{ |l| !@last_deleted_lines.detect {|n| n[:original_line] == l[:original_line]} }
    lines_that_have_been_undeleted = @last_deleted_lines.select{ |l| !deleted_lines.detect {|n| n[:original_line] == l[:original_line]} }

    lines_that_have_been_added = added_lines.select{ |l| !@last_added_lines.detect {|n| n[:original_line] == l[:original_line]} }
    lines_that_have_been_unadded = @last_added_lines.select{ |l| !added_lines.detect {|n| n[:original_line] == l[:original_line]} }


    handle_deleted_lines lines_that_have_been_deleted
    handle_added_lines lines_that_have_been_added
    handle_unadded_lines lines_that_have_been_unadded
    handle_undeleted_lines lines_that_have_been_undeleted
    reset_regions = reset_plus_regions lines_that_have_been_added, diff[:plus_regions]

    @last_added_lines = added_lines
    @last_deleted_lines = deleted_lines
  end


  def handle_deleted_lines lines
    return if lines.length == 0
    lines.each do |line|
      del_signs = signs.select {|n, s| s.original_line == line[:original_line] }
      del_signs.each { |s| unplace_sign *s }
    end
  end


  def handle_added_lines lines
    return if lines.length == 0
    lines.each do |line|
      place_sign line[:new_line], 'new'
    end
  end


  def handle_undeleted_lines lines
    return if lines.length == 0
    lines.each do |line|
      colour = "col#{@line_colourer.get_colour(line[:original_line])}"
      place_sign line[:new_line], colour
    end
  end

  def handle_unadded_lines lines
    return if lines.length == 0
    lines.each do |line|
      del_signs = signs.select {|n, s| s.original_line == line[:original_line]  && s.group == 'new'}
      del_signs.each { |s| unplace_sign *s }
      colour = "col#{@line_colourer.get_colour(line[:original_line])}"
      place_sign line[:new_line], colour
    end
  end

  def reset_plus_regions added_lines, plus_regions
    last_line = -1
    added_lines.each do |line|
      #The line above will be in the same plus region, so no need to reset again
      if line[:new_line] == last_line + 1
        last_line = line[:new_line]
        next
      end
      last_line = line[:new_line]

      reset_region = plus_regions.detect { |p| line[:new_line] >= p.first && line[:new_line] <= p.last }
      if reset_region
        Range.new(*reset_region).each do |line|
          place_sign line, 'new'
        end
      end
    end
  end

  def get_diff
    diff_gatherer.git_diff
  end

  def diff_gatherer
    @_diff_gatherer ||= DiffGatherer.new @filename, temp_filename
  end

  def temp_filename
    '/tmp/' + @filename.gsub('/', '') + 'asdf232'
  end

end
