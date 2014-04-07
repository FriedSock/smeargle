require File.join(File.dirname(__FILE__), 'jenks.rb')

class LineColourer

  # TODO, let users specify these in their .vimrc
  COLOUR_GROUPS = 6
  NOT_FINISHED = "Not finiiished"

  def initialize filename
    @filename = filename
    timestamps = generate_timestamps @filename
    fork { generate_cluster timestamps }
    fork { generate_linear timestamps }
    fork { generate_authors @filename }
  end

  def cluster_groups
    harvest_groups_from_file 'cluster'
  end

  def author_groups
    harvest_groups_from_file 'author'
  end

  def linear_groups
    harvest_groups_from_file 'linear'
  end

  def harvest_groups_from_file type
    file_name = "/tmp/.#{@filename}-#{type}"
    if !File.exist? file_name
      puts "#{type} colouring for is not ready yet"
      return default_groups
    end

    file = File.open(file_name, "rb")
    contents = file.read
    file.close
    if eval(contents) && eval(contents) != NOT_FINISHED
      eval(contents)
    else
      puts "#{type} colouring for is not ready yet"
      default_groups
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
    file_name = "/tmp/.#{filename}-author"
    File.open(file_name, 'w+') { |f| f.write "\"#{NOT_FINISHED}\"" }

    out = git_blame_output filename
    authors = out.scan(/^author (.*)$/)
    author_pairs = authors.uniq.map {|a| [a.first, authors.count(a)]}.sort {|x,y| y[1] <=> x[1]}
    named_authors = author_pairs[0..COLOUR_GROUPS-2].map {|p| p.first}
    colour_groups = authors.map { |a| named_authors.index a.first }.map {|e| e ? e : named_authors.length }

    File.open(file_name, 'w+') { |f| f.write colour_groups }
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
    file_name = "/tmp/.#{@filename}-linear"
    File.open(file_name, 'w+') { |f| f.write "\"#{NOT_FINISHED}\"" }

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

    File.open(file_name, 'w+') { |f| f.write colours }
  end

  def generate_cluster timestamps
    file_name = "/tmp/.#{@filename}-cluster"
    File.open(file_name, 'w+') { |f| f.write "\"#{NOT_FINISHED}\"" }

    cluster = Jenks.cluster timestamps.map(&:to_i), COLOUR_GROUPS
    colours = timestamps.map do |timestamp|
      cluster.find_index { |c| c.include? timestamp.to_i }
    end

    File.open(file_name, 'w+') { |f| f.write colours }
  end


  def highlight_file opts={}
    default_opts = {
      :reverse => true,
      :type => :clustered,
      :start => 232
    }
    opts = default_opts.merge opts

    if opts[:type] == :linear
      finish = opts[:start] + (COLOUR_GROUPS - 1)
      @line_colours = linear_groups.map {|c| finish - c }

    elsif opts[:type] == :clustered
      clustered_groups = cluster_groups
      unique_groups = clustered_groups.uniq.length
      finish = opts[:start] + (unique_groups - 1)
      @line_colours = clustered_groups.map {|c| finish - c }

    elsif opts[:type] = :author
      @line_colours = author_groups.map { |c| opts[:start] + c }
    end

    command = @line_colours.each_with_index do |colour, index|
      current_buffer.place_sign((index+1), "col#{colour}")
    end
  end

  def default_groups
    number_of_lines = `wc -l #{@filename}`.split.first.to_i
    ('0'*number_of_lines).split(//).map(&:to_i)
  end

end
