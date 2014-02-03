require File.join(File.dirname(__FILE__), 'identical_line_sequence.rb')

class SequenceScanner

  attr_reader :sequences

  def initialize filename
    @filename = filename
    @sequences = ranges.map do |r|
      IdenticalLineSequence.new *r
    end
  end

  def ranges
    last_line = nil
    start_of_sequence = nil
    i = 0
    line_content = nil
    ranges = []

    File.open(@filename, 'r').each do |line|
      if last_line
        if last_line == line
          start_of_sequence ||= i
          line_content ||= line
        else
          if start_of_sequence
            ranges << [start_of_sequence, i, line_content]
            start_of_sequence = nil
          end
        end
      end
      last_line = line
      i += 1
    end

    ranges << [start_of_sequence, i, line_content] if start_of_sequence
    ranges
  end

end
