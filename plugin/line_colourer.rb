require File.join(File.dirname(__FILE__), 'jenks.rb')

class LineColourer

  # TODO, let users specify these in their .vimrc
  COLOUR_GROUPS = 6
  NOT_FINISHED = "Not finiiished"

  def initialize filename, options={}
    @filename = filename
    timestamps = generate_timestamps @filename

    clear_files ['heat', 'jenks', 'author']

    fork { generate_jenks timestamps }
    fork { generate_heat timestamps }
    fork { generate_authors @filename }

    #If the user has requested it -- wait until the selected scheme has finished
    timeout = options[:timeout]
    if timeout > 0 && options.has_key?(:startup_scheme)
      return if options[:startup_scheme] == ''
      scheme = options[:startup_scheme].to_sym
      return unless [:jenks, :heat, :author].include? scheme

      busy_wait timeout, scheme
    end
  end

  def busy_wait timeout, type
    start_time = Time.new
    case type
    when :heat
      finished = lambda { heat_groups }
    when :jenks
      finished = lambda { jenks_groups }
    when :author
      finished = lambda { author_groups }
    end

    finished_or_out_of_time = lambda { finished.call || Time.new - start_time > timeout }
    while !finished_or_out_of_time.call ;  end
  end

  def cache_filename
    @filename.gsub('/', '')
  end

  def jenks_groups
    @_jenks_groups ||= harvest_groups_from_file 'jenks'
  end

  def author_groups
    @_author_groups ||= harvest_groups_from_file 'author'
  end

  def heat_groups
    @_heat_groups ||= harvest_groups_from_file 'heat'
  end

  def harvest_groups_from_file type
    file_name = "/tmp/.#{cache_filename}-#{type}"
    if !File.exist? file_name
      return nil
    end

    file = File.open(file_name, "rb")
    contents = file.read
    file.close
    if eval(contents) && eval(contents) != NOT_FINISHED
      eval(contents)
    else
      return nil
    end
  end

  def get_colour line_no
    #Need to decrement index because lines are 1 based
    @line_colours[line_no-1]
  end

  def highlight_lines opts={}
    highlight_file opts
  end

  def git_blame_output filename
    LineColourer.git_blame_output filename
  end

  def self.git_blame_output filename
    directory = filename.include?('/') ? filename.split('/')[0..-2].join('/') : '.'
    filename = filename.split('/').last
    `cd #{directory}; git blame #{filename} --line-porcelain`
  end

  def generate_authors filename
    out = git_blame_output filename
    authors = out.scan(/^author (.*)$/)
    author_pairs = authors.uniq.map {|a| [a.first, authors.count(a)]}.sort {|x,y| y[1] <=> x[1]}
    named_authors = author_pairs[0..COLOUR_GROUPS-2].map {|p| p.first}
    colour_groups = authors.map { |a| named_authors.index a.first }.map {|e| e ? e : named_authors.length }

    file_name = "/tmp/.#{cache_filename}-author"
    File.open(file_name, 'w') { |f| f.write colour_groups }
    colour_groups
  end

  def generate_timestamps filename
    harvest = false
    timestamps = []

    out = git_blame_output filename

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


  def clear_files names
    names.each do |name|
      file_name = "/tmp/.#{cache_filename}-#{name}"
      File.open(file_name, 'w') { |f| f.write "\"#{NOT_FINISHED}\"" }
    end
  end

  def generate_heat timestamps
    sorted_stamps = timestamps.map(&:to_i).uniq.sort
    smallest = sorted_stamps.first
    biggest = sorted_stamps.last
    range = COLOUR_GROUPS - 1

    #Don't want to divide by 0 if the whole file is 1 timestamp
    if biggest == smallest
      colours =  timestamps.map { COLOUR_GROUPS  - 1 }
    else
      colours = timestamps.map do |timestamp|
        (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
      end
    end

    file_name = "/tmp/.#{cache_filename}-heat"
    File.open(file_name, 'w') { |f| f.write colours }
  end

  def generate_jenks timestamps
    cluster = Jenks.cluster timestamps.map(&:to_i), COLOUR_GROUPS
    colours = timestamps.map do |timestamp|
      cluster.find_index { |c| c.include? timestamp.to_i }
    end

    file_name = "/tmp/.#{cache_filename}-jenks"
    File.open(file_name, 'w') { |f| f.write colours }
  end


  def highlight_file opts={}
    default_opts = {
      :reverse => true,
      :type => :jenks,
      :start => 232
    }
    opts = default_opts.merge opts

    handle_group_error = Proc.new do |group|
      if !group
        VIM::command('let b:colour_timeout = 1')
        return
      else
        group
      end
    end

    if opts[:type] == :heat
      handle_group_error.call(heat_groups)
      finish = opts[:start] + (COLOUR_GROUPS - 1)
      @line_colours = heat_groups.map {|c| finish -  c }

    elsif opts[:type] == :jenks
      handle_group_error.call jenks_groups
      clustered_groups = jenks_groups
      unique_groups = clustered_groups.uniq.length
      finish = opts[:start] + (unique_groups - 1)
      @line_colours = clustered_groups.map {|c| finish - c }

    elsif opts[:type] = :author
      handle_group_error.call author_groups
      @line_colours = author_groups.map { |c| opts[:start] + c }
    end

    command = @line_colours.each_with_index do |colour, index|
      current_buffer.place_sign((index+1), "col#{colour}")
    end

  end

end
