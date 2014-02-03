class Buffer

  attr_accessor :sequences, :sequence_scanner

  def initialize filename
    @filename = filename
    @sequence_scanner = SequenceScanner.new(filename)
  end

  def find_current_sequence line
    @sequence_scanner.current_sequence line
  end

end
