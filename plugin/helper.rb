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
  bufname = VIM::evaluate "expand('%')"
  command = "let b:original_buffer_name='#{bufname}'"
  VIM::command command
  $Buffers[bufname] = Buffer.new bufname
end

def current_buffer
  bufname = VIM::evaluate "b:original_buffer_name"
  $Buffers[bufname]
end

def highlight_lines *args
  current_buffer.highlight_lines *args if current_buffer
end

