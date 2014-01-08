require '~/.vim/bundle/git-off-my-lawn/plugin/jenks.rb'

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

  highlight_file timestamps, new_name, :reverse => true
end

def highlight_lines
  filename = VIM::Buffer.current.name
  size = VIM::Buffer.current.length

  timestamps = generate_timestamps size, filename

  highlight_file timestamps, filename, :reverse  => true, :type => :clustered
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
      cluster = Jenks.cluster timestamps.map(&:to_i), range
      if opts[:reverse]
        colours = timestamps.map do |timestamp|
          i = cluster.find_index { |c| c.include? timestamp.to_i }
          opts[:finish] - i
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
    VIM::command('highlight ' + 'col' + c.to_s + ' ctermbg=' + c.to_s + 'guibg=' + c.to_s)
    VIM::command('sign define ' + 'col' + c.to_s + ' linehl=' + 'col' + c.to_s)
  end

  command = colours.each_with_index do |colour, index|
    command = 'sign place ' + colour.to_s + ' name=col' + colour.to_s + ' line=' + (index+1).to_s + ' file=' + filename
    VIM::command(command)
  end

end

VIM::command('highlight new ctermbg=52 guibg=52')
VIM::command('sign define new linehl=new')


def changedlines file1, file2
  diffout = `diff #{file1} #{file2} | sed '/^[<|>|-]/ d' | tr '\n' ' '`

  VIM::command('let b:changed_lines = []')

  diffout.split(' ').each do |str|
    return if '<>-'.include? str[0]

    if str.include? 'a'
      range = str.split('a')[1..-1]
    elsif str.include? 'c'
      range = str.split('c')[1..-1]
    else
      break
    end

    range.each do |s|
      r = extract_range(s)
      r.each do |n| VIM::command("let b:changed_lines = b:changed_lines + [#{n}]") end
    end
  end

  cache_exists = VIM::evaluate("exists('b:last_changed_lines')") == 1
  unless cache_exists && VIM::evaluate('b:changed_lines') == VIM::evaluate('b:last_changed_lines')
    signs = VIM::evaluate('GetSigns()')
    remove_red_lines signs
    VIM::evaluate('b:changed_lines').each do |l| place_sign l, file1 end
  end

  VIM::command("let b:last_changed_lines = b:changed_lines")
end

def place_sign line_no, filename
  VIM::command('sign place ' + line_no.to_s + ' name=new line=' +  line_no.to_s + ' file=' + filename)
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

