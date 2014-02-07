class Sign

  attr_accessor :line, :original_line, :group

  def initialize line, group
    @line = line
    @original_line = line
    @group = group
  end

  def move_down
    @line += 1
  end

  def move_up
    @line -= 1
  end

end
