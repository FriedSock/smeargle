ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';

function! OpenWindow()
  ruby open_window
endfunction

function! HighlightNow()
  ruby highlight_now
endfunction

function! Unhighlight()
  sign unplace *
endfunction

function! SplitWindow(new_name)
  set scrollbind
  vertical 20 new
  exec 'edit ' . a:new_name
  set bt=nofile
  normal! GGdd
  set scrollbind
  syncbind
endfunction

function! DiffMe()
  ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';
  let file1 = expand('%')
  let file2 = '/tmp/' . substitute(file1, '/', '', '') . 'funny'
  silent exec 'write! ' . file2
  "!diff % - || :

  let command = "ruby changedlines '" . file1 . "', '" . file2 . "'"
  exec command
endfunction
