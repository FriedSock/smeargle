module Kernel
  def puts s
    VIM::command("echom '#{s}'")
  end
end
