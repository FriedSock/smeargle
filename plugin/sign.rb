class Sign

  attr_accessor :line, :original_line, :group, :line_content

  def initialize line, group, line_content
    @line = line
    @original_line = line
    @group = group
    @line_content = line_content
  end

  def move_down
    @line += 1
  end

  def move_up
    @line -= 1
  end

end
