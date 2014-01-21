class Array

  def to_s
    '[' + self.map(&:to_s).join(',') + ']'
  end

end
