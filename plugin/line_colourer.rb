require File.join(File.dirname(__FILE__), 'jenks.rb')

class LineColourer

  # TODO, let users specify these in their .vimrc
  COLOUR_GROUPS = 6

  def initialize filename
    @timestamps = generate_timestamps filename
    @linear_groups = generate_linear @timestamps
    @clustered_groups = generate_cluster @timestamps
    @author_groups = generate_authors filename
  end

  def get_colour line_no
    #Need to decrement index because lines are 1 based
    @line_colours[line_no-1]
  end

  def highlight_lines opts={}
    default_opts = {
      :reverse => true,
      :type => :clustered
    }

    opts = default_opts.merge opts
    highlight_file @timestamps, @filename, :reverse  => opts[:reverse], :type => opts[:type]
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

  def generate_linear timestamps
    sorted_stamps = timestamps.map(&:to_i).uniq.sort
    smallest = sorted_stamps.first
    biggest = sorted_stamps.last
    range = COLOUR_GROUPS - 1

    #Don't want to divide by 0 if the whole file is 1 timestamp
    if biggest == smallest
      return timestamps.map { COLOUR_GROUPS  - 1 }
    end

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
    finish = opts[:start] + COLOUR_GROUPS - 1
    @linear_line_colours = @linear_groups.map {|c| finish - c }

    unique_groups = @clustered_groups.uniq.length
    finish = opts[:start] + (unique_groups - 1)
    @clustered_line_colours = @clustered_groups.map {|c| finish - c }

    @author_line_colours = @author_groups.map {|c| finish - c}

    if opts[:type] == :linear
      @line_colours = @linear_line_colours
    elsif opts[:type] == :clustered
      @line_colours = @clustered_line_colours
    elsif opts[:type] = :author
      @line_colours = @author_line_colours
    end


    command = @line_colours.each_with_index do |colour, index|
      current_buffer.place_sign((index+1), "col#{colour}")
    end
  end

end
