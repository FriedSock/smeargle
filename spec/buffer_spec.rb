require 'plugin/buffer.rb'
require 'rspec'
require 'ruby-debug'

describe Buffer do

  before do
    filename = 'Necrophile'
    @buffer = Buffer.new filename
  end

end
