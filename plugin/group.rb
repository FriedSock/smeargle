class Group

  attr_reader :name, :highlight_group

  def initialize name, highlight_group
    @name = name
    @highlight_group = highlight_group
    VIM::command "sign define #{name} linehl=#{highlight_group}"
  end

  def ids
    @_ids ||= Set.new
  end

  def add_sign id
    return nil if ids.include? id
    ids.add id
  end

  def remove_sign id
    return nil unless ids.include? id
    ids.delete id
  end

end
