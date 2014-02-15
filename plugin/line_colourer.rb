class LineColourer

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
    range = 6
    colours = timestamps.map do |timestamp|
      (((timestamp.to_i - smallest).to_f / (biggest - smallest))*range).round
    end
  end

  def generate_cluster timestamps
    cluster = Jenks.cluster timestamps.map(&:to_i), 6
    colours = timestamps.map do |timestamp|
      cluster.find_index { |c| c.include? timestamp.to_i }
    end
  end


  def highlight_file timestamps, filename, opts={}

    default_opts = {
      :reverse => false,
      :type => :linear,
      :finish => 238
    }
    opts = default_opts.merge opts


    if opts[:type] == :linear
      @line_colours = @linear_groups.map {|c| opts[:finish] - c }
    elsif opts[:type] == :clustered
      @line_colours = @clustered_groups.map {|c| opts[:finish] - c }
    end

    @line_colours.uniq.each do |c|
      name = 'col' + c.to_s
      current_buffer.define_sign name, name
    end
    current_buffer.define_sign 'new', 'new'
    puts @line_colours

    command = @line_colours.each_with_index do |colour, index|
      current_buffer.place_sign((index+1), "col#{colour}")
    end
  end

end
