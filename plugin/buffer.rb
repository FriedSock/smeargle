require File.join(File.dirname(__FILE__), 'group.rb')
require File.join(File.dirname(__FILE__), 'sign.rb')
require File.join(File.dirname(__FILE__), 'diff_gatherer.rb')
require File.join(File.dirname(__FILE__), 'line_colourer.rb')
require File.join(File.dirname(__FILE__), 'sequence_scanner.rb')
require File.join(File.dirname(__FILE__), 'mapper.rb')

class Buffer

  def initialize filename, colour_options
    @filename = filename
    ['col232', 'col233', 'col234', 'col235', 'col236', 'col237', 'col238', 'new'].each { |c| define_sign c, c }
    @line_colourer = LineColourer.new filename, colour_options
    @sequence_scanner = SequenceScanner.new(filename)
    @last_deleted_lines = []
    @last_added_lines = []
    $id ||= 0
  end

  def highlight_lines opts={}
    reset_add_delete_lists
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
    handle_unadded_lines lines_that_have_been_unadded
    handle_undeleted_lines lines_that_have_been_undeleted
    reset_regions = reset_plus_regions lines_that_have_been_added, diff[:plus_regions]
    other_reset_regions = reset_unchanged_regions lines_that_have_been_added, lines_that_have_been_deleted, false
    other_reset_regions = reset_unchanged_regions lines_that_have_been_undeleted, lines_that_have_been_unadded, true

    mapper = Mapper.new added_lines, deleted_lines
    reset_sequences mapper
    handle_added_lines added_lines

    @last_added_lines = added_lines
    @last_deleted_lines = deleted_lines
  end

  def reset_sequences mapper
    @sequence_scanner.ranges.each do |r|
      (r[0]..r[1]).each do |l|
        new_line = mapper.map l
        colour = "col#{@line_colourer.get_colour l}"
        place_sign new_line, colour
      end
    end
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

      colour_code =  @line_colourer.get_colour(line[:original_line])
      if colour_code
        colour = "col#{colour_code}"
        place_sign line[:new_line], colour
      end
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

  def reset_unchanged_regions added_lines, deleted_lines, un
    return if added_lines.empty? || deleted_lines.empty?
    sorted_added_lines = added_lines.map {|l| l.clone }
    sorted_deleted_lines = deleted_lines.map {|l| l.clone}

    trim_outliers = lambda do |arr|
      new_arr = arr.map { |l| l.clone}
      remove_consecutives = lambda do |array|
        arr.each_cons(2) do |h1, h2|
          array.delete h1 if h1[:type] == h2[:type]
        end
      end
      remove_consecutives.call arr
      remove_consecutives.call arr.reverse
      return new_arr
    end

    merged_lines = (sorted_added_lines.map {|l| l.tap { |t| l[:type] = :add }} + sorted_deleted_lines.map {|l| l.tap { |t| l[:type] = :del }})
    sorted_merged_lines = merged_lines.sort { |l1, l2| l1[:new_line] <=> l2[:new_line] }
    sorted_merged_lines = trim_outliers.call sorted_merged_lines
    no_changes, changes = remove_changes sorted_merged_lines

    out_array = []
    original_to_new_difference = 0
    ([nil] + no_changes).each_cons(2) do |previous, current|
      update_difference = lambda do
        #If there is a deletion, we want the line below, and we will be taking the difference
        #away to find the original line so we add one. otherwise we want the line above, so we
        #take one away
        if un
          extra_difference = 0
        else
          extra_difference = current[:type] == :add ? 1 : -1
        end
        original_to_new_difference  += extra_difference
      end

      if !previous
        original_to_new_difference = current[:new_line] - current[:original_line]
        update_difference.call
        next
      end
      start = previous[:type] == :add ? previous[:new_line]+1 : previous[:new_line]
      finish = current[:type] == :add ? current[:new_line]-1 : current[:new_line]
      range = (start..finish)
      range.each do |l|
        out_array << {:new_line => l, :original_line  => l-original_to_new_difference } if !changes.include? l
      end
      update_difference.call
    end

    out_array.each do |line|
      colour = "col#{@line_colourer.get_colour(line[:original_line])}"
      place_sign line[:new_line], colour
    end
  end

  def remove_changes lines
      just_adds_and_dels = lines.dup
      changed_lines = []
      lines.each_cons(2) do |h1,h2|
        if h1[:type] != h2[:type] && h1[:new_line] == h2[:new_line]
          just_adds_and_dels.delete h1
          just_adds_and_dels.delete h2
          changed_lines << (h1[:type] == :add ? h1 : h2)[:new_line]
        end
      end
      return [just_adds_and_dels, changed_lines]
  end

  def get_diff
    diff_gatherer.git_diff
  end

  def reset_add_delete_lists
    @last_deleted_lines = []
    @last_added_lines = []
  end

  def diff_gatherer
    @_diff_gatherer ||= DiffGatherer.new @filename, temp_filename
  end

  def temp_filename
    '/tmp/' + @filename.gsub('/', '') + 'asdf232'
  end

end
