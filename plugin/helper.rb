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

