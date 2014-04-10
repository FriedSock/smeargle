module Kernel
  def puts s
    VIM::command("redraw | echom '#{s}'")
  end
end
