ruby load 'helper.rb';

function! Blame(filename, line)
  return system('git blame ' . a:filename . ' -L ' . a:line . ',' . a:line)
endfunction

function! ShellCall(command)
  return system(a:command)
endfunction

function! OpenWindow()
  ruby open_window
endfunction

function! HighlightNow()
  ruby highlight_now
endfunction

function Unhighlight()
  exec('sign unplace *')
endfunction
