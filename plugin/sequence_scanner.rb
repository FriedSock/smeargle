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

  def current_sequence line
    @sequences.detect { |s| s.contains_line? line }
  end

  def extending_sequence line, content
    @sequences.detect { |s| s.is_extended_by? line, content }
  end

  def notify_addition line, line_content, line_above_content, line_below_content
    contained = false

    @sequences.map! do |s|
      if s.contains_line? line
        contained = true
        if s.content == line_content
          s.grow
          s
        else
          s1, s2 = s.cut line
          s2.move_down if s2
          [s1, s2]
        end
      elsif line < s.start
        s.move_down
        s
      else
        s
      end
    end
    @sequences.flatten!
    @sequences.compact!

    if !contained
      #The addition may create a new sequence
      if line_content == line_above_content
        if line_content == line_below_content
          @sequences << IdenticalLineSequence.new((line-1), (line+1), line_content)
        else
          @sequences << IdenticalLineSequence.new((line-1), line, line_content)
        end
      elsif line_content == line_below_content
        @sequences << IdenticalLineSequence.new(line, (line+1), line_content)
      end
    end
    @sequences.sort! { |a,b| a.start <=> b.start }
  end

  #Note: there is a precondition that @sequences be sorted
  def notify_deletion line
    @sequences.map do |s|
      if s.contains_line? line
        s.shrink
        s
      elsif line < s.start
        s.move_up
        s
      end
    end
    @sequences.flatten!
    @sequences.compact!

    #Try and merge 2 sequences
    @sequences = @sequences.inject do |arr, seq2|
      if arr.respond_to? :last
        seq1 == arr.last
        array = arr[0..-2]
      else
        seq1 = arr
        array = []
      end

      if (seq1.finish+1) == seq2.start && seq1.content == seq2.content
        array << seq1.coalesce(seq2)
      else
        array << seq1 << seq2
      end
    end
  end

end
