class LineColourer

  # TODO, let users specify these in their .vimrc
  COLOUR_GROUPS = 6

  def initialize filename
    @timestamps = generate_timestamps filename
    @linear_groups = generate_linear @timestamps
    @clustered_groups = generate_cluster @timestamps
  end

  def highlight_lines opts={}
    default_opts = {
      :reverse => true,
      :type => :clustered
    }

    opts = default_opts.merge opts
    highlight_file @timestamps, @filename, :reverse  => opts[:reverse], :type => opts[:type]
  end

  def generate_timestamps filename
    harvest = false
    timestamps = []

    #TODO: is this in the right place?
    directory = filename.include?('/') ? filename.split('/')[0..-2].join('/') : '.'
    filename = filename.split('/').last
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

  def generate_linear timestamps
    sorted_stamps = timestamps.map(&:to_i).uniq.sort
    smallest = sorted_stamps.first
    biggest = sorted_stamps.last
    range = COLOUR_GROUPS

    colours = timestamps.map do |timestamp|
      (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
    end
  end

  def generate_cluster timestamps
    cluster = Jenks.cluster timestamps.map(&:to_i), COLOUR_GROUPS
    colours = timestamps.map do |timestamp|
      cluster.find_index { |c| c.include? timestamp.to_i }
    end
  end


  def highlight_file timestamps, filename, opts={}

    default_opts = {
      :reverse => false,
      :type => :linear,
      :start => 232
    }
    opts = default_opts.merge opts


    unique_groups = @linear_groups.uniq.length
    finish = opts[:start] + COLOUR_GROUPS
    @linear_line_colours = @linear_groups.map {|c| finish - c }

    unique_groups = @clustered_groups.uniq.length
    finish = opts[:start] + (unique_groups - 1)
    @clustered_line_colours = @clustered_groups.map {|c| finish - c }

    if opts[:type] == :linear
      @line_colours = @linear_line_colours
    else
      @line_colours = @clustered_line_colours
    end


    command = @line_colours.each_with_index do |colour, index|
      current_buffer.place_sign((index+1), "col#{colour}")
    end
  end

end
