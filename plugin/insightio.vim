ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';

function! OpenWindow()
  ruby open_window
endfunction

function! HighlightNow()
  ruby highlight_now
endfunction

function Unhighlight()
  exec('sign unplace *')
endfunction

function! SplitWindow(new_name)
  exec 'set scrollbind'
  exec 'vertical 20 new'
  exec 'edit ' . a:new_name
  exec 'set bt=nofile'
  exec 'normal GGdd'
  exec 'set scrollbind'
  exec 'syncbind'
endfunction

