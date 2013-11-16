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

  timestamps = generate_timestamps size, filename
  timestamps.each_with_index do |t, i| new_buffer.append i, '' end

  VIM::command("call SplitWindow('#{new_name}')")

  highlight_things timestamps, new_name, :reverse => true
end

def highlight_now
  filename = VIM::Buffer.current.name
  size = VIM::Buffer.current.length

  timestamps = generate_timestamps size, filename

  highlight_things timestamps, filename, :reverse  => true
end

def generate_timestamps size, filename
  harvest = false
  timestamps = []

  out = `git blame #{filename} --line-porcelain`
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


def highlight_things timestamps, filename, opts={}

  default_opts = {
    :reverse => false,
    :start => 233,
    :finish => 238
  }
  opts = default_opts.merge opts

  range = opts[:finish] - opts[:start]

  sorted_stamps = timestamps.map(&:to_i).uniq.sort
  smallest = sorted_stamps.first
  biggest = sorted_stamps.last

  if biggest.to_i == smallest.to_i
    colours = [start] * timestamps.size
  else
    if opts[:reverse]
      colours = timestamps.map do |timestamp|
        opts[:finish] - (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
      end
    else
      colours = timestamps.map do |timestamp|
        opts[:start] + (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
      end
    end
  end

  colours.uniq.each do |c|
    VIM::command('highlight ' + 'col' + c.to_s + ' ctermbg=' + c.to_s + 'guibg=' + c.to_s)
    VIM::command('sign define ' + 'col' + c.to_s + ' linehl=' + 'col' + c.to_s)
  end

  command = colours.each_with_index do |colour, index|
    command = 'sign place ' + colour.to_s + ' name=col' + colour.to_s + ' line=' + (index+1).to_s + ' file=' + filename
    VIM::command(command)
  end

end

VIM::command('highlight new ctermbg=100 guibg=100')
VIM::command('sign define new linehl=new')


def changedlines file1, file2
  diffout = `diff #{file1} #{file2} | tr '\n' ' ' | sed 's/<//g;s/>//g'`

  diffout.split(' ').each do |s|
    handle_exp s, file1
  end
end


def handle_exp str, filename
  if str.include? 'a'
    str.split('a').each do |s| place_signs(extract_range(s), filename) end
  elsif str.include? 'd'
    str.split('d').each do |s| place_signs(extract_range(s), filename) end
  elsif str.include? 'c'
    str.split('c').each do |s| place_signs(extract_range(s), filename) end
  end
end

def place_signs range, filename
  range.each do |line_no|
    VIM::command('sign place new name=new line=' +  line_no.to_s + ' file=' + filename)
  end
end

#Returns a number or a range of numbers
def extract_range str
  if str.include? ','
    Range.new *str.split(',').map(&:to_i)
  else
    Range.new *str.to_i.to_a*2
  end
end
