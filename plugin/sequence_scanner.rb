class SequenceScanner

  def initialize filename
    @filename = filename
  end

  def ranges
    last_line = nil
    start_of_sequence = nil
    i = 0
    ranges = []

    File.open(@filename, 'r').each do |line|
      if last_line
        if last_line == line
          start_of_sequence ||= i
        else
          if start_of_sequence
            ranges << [start_of_sequence, i]
            start_of_sequence = nil
          end
        end
      end
      last_line = line
      i += 1
    end

    ranges << [start_of_sequence, i] if start_of_sequence
    ranges
  end

end
