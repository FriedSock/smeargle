require 'rspec'

RSpec.configure do |config|

  config.before(:each) do
    buffer_name = 'Buffer naym'
    buffer_number = 1

    vim = lambda do |input|
      case input
      when "expand('%')"
        'buffer name'
      when "bufnr('#{buffer_name}')"
        buffer_number
      end
    end

    vi = double
    stub_const('VIM', vi)
    vi.stub(:command) { |c| vim.call c }
    vi.stub(:evaluate) { |c| vim.call c }
  end
end

