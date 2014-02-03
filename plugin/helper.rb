require '~/.vim/bundle/git-off-my-lawn/plugin/jenks.rb'
require '~/.vim/bundle/git-off-my-lawn/plugin/array.rb'
require '~/.vim/bundle/git-off-my-lawn/plugin/sequence_scanner.rb'

def get_first_number string
  string.split(' ')[1..-1].each do |token|
    if token.to_i.to_s.to_i != 0
      return token
    end
  end
  return 'Aint been commited yet!'
end

def open_window
  filename = VIM::Buffer.current.name
  size = VIM::Buffer.current.length

  new_name = filename + '-prime'
  VIM::command("badd #{new_name}")
  new_buffer = VIM::Buffer[VIM::Buffer.count-1]

  timestamps = generate_timestamps filename
  timestamps.each_with_index do |t, i| new_buffer.append i, '' end

  VIM::command("call SplitWindow('#{new_name}')")

  highlight_file timestamps, new_name, :reverse => true
end

def highlight_lines opts={}
  default_opts = {
    :reverse => true,
    :type => :clustered
  }

  opts = default_opts.merge opts
  filename = VIM::Buffer.current.name
  size = VIM::Buffer.current.length

  timestamps = generate_timestamps filename

  highlight_file timestamps, filename, :reverse  => opts[:reverse], :type => opts[:type]
end

def generate_timestamps filename
  harvest = false
  timestamps = []

  #TODO: is this in the right place?
  directory = filename.split('/')[0..-2].join('/')
  out = `cd #{directory}; git blame #{filename} --line-porcelain`

  out.split(' ').each do |t|
    if harvest
      timestamps << t
      harvest = false
    elsif t=='committer-time'
      harvest = true
    end
  end
  timestamps
end


def highlight_file timestamps, filename, opts={}

  default_opts = {
    :reverse => false,
    :start => 232,
    :type => :linear,
    :finish => 238
  }
  opts = default_opts.merge opts

  range = opts[:finish] - opts[:start]

  sorted_stamps = timestamps.map(&:to_i).uniq.sort
  smallest = sorted_stamps.first
  biggest = sorted_stamps.last

  if biggest.to_i == smallest.to_i
    colours = [opts[:start]]
  else
    if opts[:type] == :linear
      if opts[:reverse]
        colours = timestamps.map do |timestamp|
          opts[:finish] - (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
        end
      else
        colours = timestamps.map do |timestamp|
          opts[:start] + (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
        end
      end
    elsif opts[:type] == :clustered
      colours = [opts[:start]]
      cluster = Jenks.cluster timestamps.map(&:to_i), 3
      if opts[:reverse]
        colours = timestamps.map do |timestamp|
          i = cluster.find_index { |c| c.include? timestamp.to_i }
          opts[:finish] - i*3
        end
      else
        colours = timestamps.map do |timestamp|
          i = cluster.find_index { |c| c.include? timestamp.to_i }
          opts[:finish] - i
        end
      end
    else
      colours = [opts[:start]]
    end
  end

  colours.uniq.each do |c|
    #TODO: Is this line needed any more?
    VIM::command('highlight ' + 'col' + c.to_s + ' ctermbg=' + c.to_s + 'guibg=' + c.to_s)
    name = 'col' + c.to_s
    VIM::command("call DefineSign('#{name}', '#{name}')")
  end

  command = colours.each_with_index do |colour, index|
    command = "call PlaceSign('#{(index+1)}', 'col#{colour}','#{filename}')"
    VIM::command(command)
  end

end



def changedlines file1, file2
  diffout = `diff #{file1} #{file2} | sed '/^[<|>|-]/ d' | tr '\n' ' '`


  added_lines = []
  changed_lines = []
  deleted_lines = []

  diffout.split(' ').each do |str|
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

  cache_exists = VIM::evaluate("exists('b:last_changed_lines')") == 1
  if !cache_exists
    VIM::command("let b:last_added_lines = []")
    VIM::command("let b:last_changed_lines = []")
    VIM::command("let b:last_deleted_lines = []")
  end

  last_added_lines = VIM::evaluate('b:last_added_lines')
  last_changed_lines = VIM::evaluate('b:last_changed_lines')
  last_deleted_lines = VIM::evaluate('b:last_deleted_lines')

  lines_that_have_been_deleted = deleted_lines - last_deleted_lines
  lines_that_have_been_undeleted = last_deleted_lines - deleted_lines

  lines_that_have_changed = changed_lines - last_changed_lines
  lines_that_have_unchanged = last_changed_lines - changed_lines

  lines_that_have_been_added = added_lines - last_added_lines
  lines_that_have_been_unadded = last_added_lines - added_lines

  puts "Undeleted lines: " + lines_that_have_been_undeleted.to_s
  puts "Deleted lines: " + lines_that_have_been_deleted.to_s

  handle_added_lines lines_that_have_been_added

  #Remember, the last sign used to be on this line so we need to move it back up later
  move_signs_up lines_that_have_been_unadded


  move_signs_up lines_that_have_been_deleted
  archive_signs lines_that_have_been_deleted

  handle_undeleted_lines lines_that_have_been_undeleted

  #TODO: Changed lines

#
#  unless cache_exists && VIM::evaluate('b:changed_lines') == VIM::evaluate('b:last_changed_lines')
#    changed_lines = '[' + VIM::evaluate('b:changed_lines').join(',') + ']'
#
#    lines_to_remove = last_changed_lines - eval(changed_lines)
#    lines_to_add = eval(changed_lines) - last_changed_lines
#
#    lines_to_add.each do |l| place_sign l, file1 end
#    lines_to_remove.each do |l| VIM::command("call UnplaceSign(#{l})") end
#  end

  VIM::command("let b:last_added_lines = #{added_lines}")
  VIM::command("let b:last_changed_lines = #{changed_lines}")
  VIM::command("let b:last_deleted_lines = #{deleted_lines}")
end

def place_sign line_no, filename
  command =  "call PlaceSign('#{line_no}', 'new', '#{filename}')"
  VIM::command command
end

#Returns a number or a range of numbers
def extract_range str
  if str.include? ','
    Range.new *str.split(',').map(&:to_i)
  else
    Range.new *[str.to_i]*2
  end
end

def remove_red_lines signs_raw
  ar = signs_raw.split

  #line, id, name
  ar.each_with_index do |s, i|

    if s.include?('name') && s.split('=')[1] == 'new'
      id = ar[i-1].split('=')[1]
      VIM::command 'sign unplace ' + id
    end
  end
end

def generate_key
  #Just working for clustered for now.
end

def handle_added_lines line
  #TODO: Make this work for more than one added line
  return if line.length == 0
  line = line.first
  VIM::command "call MoveSignsDown(#{line})"
end

#Called on any items that are deleted
def move_signs_up line
  #TODO: Make this work for more than one deleted line
  return if line.length == 0
  line = line.first

  sequence = find_current_sequence line
  if sequence.min == sequence.max
    VIM::command "call MoveSignsUp(#{line})"
  else
    puts "sequence: " + sequence.to_a[0..-2].to_s
    VIM::command("call ReinstateSequence(#{sequence.to_a[0..-2]})")
    VIM::command("call MoveSignsUp(#{sequence.last})")
  end
end

def archive_signs line
  #TODO: Make this work for more than one line
  return if line.length == 0
  line = line.first
  VIM::command "call ArchiveSign(#{line})"
end

def handle_undeleted_lines line
  puts "lines: " + line.to_s
  #TODO: Make this work for more than one line
  return if line.length == 0
  line = line.first

  #If the line is part of an identical sequence, then the whole sequence
  #needs to be refreshed
  sequence = find_current_sequence line
  if sequence.min == sequence.max
    VIM::command("call MoveSignsDown(#{sequence.last - 1})")
    VIM::command("call ReinstateSign(#{sequence.first})")
  else
    VIM::command("call ReinstateSequence(#{sequence.to_a})")
    VIM::command("call MoveSignsDown(#{sequence.last})")
  end
end


def find_current_sequence line
  VIM::evaluate('b:sequences').each do |s|
    if line >= s.first && line <= s.last
      #line is inside sequence
      return s.first..s.last
    end
  end
  line..line
end

def find_sequences
  filename = VIM::evaluate("bufname('%')")
  sequences = SequenceScanner.new(filename).ranges.map{ |t| t[0..-2]}
  VIM::command "let b:sequences = #{sequences}"
end

