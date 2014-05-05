class Mapper

  #take the format of [range, difference]
  def initialize added_lines, deleted_lines
    @map = []
    merged_lines = (deleted_lines.map {|l| l.tap { |t| l[:type] = :del }} + added_lines.map {|l| l.tap { |t| l[:type] = :add }})
    merged_lines = merged_lines.sort { |l1, l2| l1[:new_line] <=> l2[:new_line] }
    first = true

    running_diff = 0
    region_start = 1
    last = 1
    last_type = nil
    merged_lines.each do |l|
      if l[:type] == :add
        if last_type != :add || l[:original_line] > last + 1
          @map << [[region_start,l[:new_line]], running_diff]
        end
        running_diff += 1
        last_type = :add
      else
        @map << [[l[:original_line],l[:original_line]], nil]
        if l[:original_line] > last + 1
          @map << [[region_start,l[:new_line]], running_diff]
        end
        running_diff -= 1
        last_type = :del
      end
      last = l[:original_line]
      region_start = @map.last[0].last + 1
      first = false
    end

    if @map.empty?
      @map = [[[1, 1000000], 0]]
    else
      @map << [[(@map.last[0][1]+1), 10000], running_diff]
    end
  end

  def map original_line
    @map.each do |m|
      range = m[0]
      next if original_line > range.last
      return m[1] ? original_line + m[1] : nil
    end
  end
end
