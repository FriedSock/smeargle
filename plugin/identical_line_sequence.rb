class IdenticalLineSequence

  attr_reader :start, :finish, :content

  def initialize start, finish, content
    @start = start
    @finish = finish
    @content = content
  end

  def self.build start, finish, content
    return nil if start >= finish
    IdenticalLineSequence.new start, finish, content
  end

  #Splits the sequence into 2 pieces by way of removing an internal section
  def eviscerate line_number
    if line_number < @start
      return nil, nil
    elsif line_number == @start
      return nil, IdenticalLineSequence.build((@start+1), @finish, @content)
    elsif line_number == @finish
      return IdenticalLineSequence.build(@start, (@finish-1), @content)
    elsif line_number > @finish
      return nil, nil
    else
      #A line in the middle has been changed
      seq1 = IdenticalLineSequence.build(@start, (line_number-1), @content)
      seq2 = IdenticalLineSequence.build((line_number+1), @finish, @content)
      return seq1, seq2
    end
  end

  #Splits the sequence into 2 pieces, all elements are intact, the specified
  #line will be in the second half
  def cut line_number
    if line_number > @start && line_number < @finish
      seq1 = IdenticalLineSequence.build(@start, (line_number-1), @content)
      seq2 = IdenticalLineSequence.build(line_number, @finish, @content)
      return seq1, seq2
    else
      return eviscerate line_number
    end
  end

  def grow
    @finish +=1
  end

  def shrink
    @finish -=1
  end

  def coalesce other_sequence
    @finish = other_sequence.finish
    self
  end

  def move_down
    @start += 1
    @finish += 1
  end

  def move_up
    @start -= 1
    @finish -= 1
  end

  def contains_line? line
    line >= @start && line <= @finish
  end

  def range
    @start..@finish
  end

end
