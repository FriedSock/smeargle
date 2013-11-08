def get_first_number string
  string.split(' ')[1..-1].each do |token|
    if token.to_i.to_s.to_i != 0
      return token
    end
  end
  return 'Aint been commited yet!'
end

def run
  filename = VIM::Buffer.current.name
  size = VIM::Buffer.current.length

  new_name = filename + '-prime'
  VIM::command("badd #{new_name}")
  new_buffer = VIM::Buffer[VIM::Buffer.count-1]

  timestamps = []
  (1..size).each do |line|
    command = 'git blame ' + filename + ' -L ' + line.to_s + ',' + line.to_s + ' -t'
    git_out = VIM::evaluate("ShellCall('" + command + "')")

    timestamp = get_first_number git_out
    new_buffer.append line-1, timestamp
    timestamps << timestamp
  end

  VIM::command('vertical 20 new')
  VIM::command('edit ' + new_name)
  VIM::command('normal GGdd')

  highlight_things timestamps
end

def highlight_things timestamps

  different_colours = timestamps.uniq.size
  start = 232
  finish = 237
  range = finish - start

  sorted_stamps = timestamps.map(&:to_i).uniq.sort
  smallest = sorted_stamps.first
  biggest = sorted_stamps.last

  colours = timestamps.map do |timestamp|
    (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round + start
  end

  puts colours

  colours.uniq.each do |c|
    VIM::command('highlight ' + 'col' + c.to_s + ' ctermbg=' + c.to_s + 'guibg=' + c.to_s)
    VIM::command('sign define ' + 'col' + c.to_s + ' linehl=' + 'col' + c.to_s)
  end

  colo_hash = {}
  command = colours.each_with_index do |colour, index|
    #colo_hash['col' + colour.to_s] ||= []
    #colo_hash['col' + colour.to_s] << ('\%' + (index+1).to_s + 'l')
    command = 'sign place ' + colour.to_s + ' name=col' + colour.to_s + ' line=' + (index+1).to_s + ' file=helper.rb'
    #puts command
    VIM::command(command)
  end

  #colo_hash.each do |hash, value|
  #  reginald = '/' + value.join('\|') + '/'
  #  command = 'syntax match ' + hash + ' ' + reginald
  #  VIM::command(command)
  #  puts command
  #end


end
