require '~/.vim/bundle/git-off-my-lawn/plugin/jenks.rb'
require '~/.vim/bundle/git-off-my-lawn/plugin/array.rb'
require '~/.vim/bundle/git-off-my-lawn/plugin/sequence_scanner.rb'
require '~/.vim/bundle/git-off-my-lawn/plugin/buffer.rb'

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
    name = 'col' + c.to_s
    current_buffer.define_sign name, name
  end
  current_buffer.define_sign 'new', 'new'

  command = colours.each_with_index do |colour, index|
    current_buffer.place_sign((index+1), "col#{colour}")
  end

end

def changedlines file1, file2
  current_buffer.consider_last_change
end

def place_sign line_no, filename
  command =  "call PlaceSign('#{line_no}', 'new', '#{filename}')"
  VIM::command command
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
  if !sequence
    VIM::command "call MoveSignsUp(#{line})"
  else
    #puts "sequence: " + sequence.to_s
    VIM::command("call ReinstateSequence(#{sequence.range.to_a})")
    VIM::command("call MoveSignsUp(#{sequence.finish})")
  end
end

def archive_signs line
  #TODO: Make this work for more than one line
  return if line.length == 0
  line = line.first
  VIM::command "call ArchiveSign(#{line})"
end

def handle_undeleted_lines line
  #puts "lines: " + line.to_s
  #TODO: Make this work for more than one line
  return if line.length == 0
  line = line.first

  #If the line is part of an identical sequence, then the whole sequence
  #needs to be refreshed
  sequence = find_current_sequence line
  if !sequence
    VIM::command("call MoveSignsDown(#{line - 1})")
    VIM::command("call ReinstateSign(#{line})")
  else
    VIM::command("call ReinstateSequence(#{sequence.range.to_a})")
    VIM::command("call MoveSignsDown(#{sequence.finish})")
  end
end


def find_current_sequence line
  current_buffer.find_current_sequence line
end

def initialize_buffer
  $Buffers ||= {}
  bufname = VIM::evaluate "bufname('%')"
  $Buffers[bufname] = Buffer.new bufname
end

def current_buffer
  bufname = VIM::evaluate "bufname('%')"
  $Buffers[bufname]
end

