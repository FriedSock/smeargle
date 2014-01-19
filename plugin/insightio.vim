ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';
ruby load '~/.vim/bundle/git-off-my-lawn/plugin/puts.rb';

function! OpenWindow()
  ruby open_window
endfunction

function! HighlightAllLines()
  sign unplace *
  ruby highlight_lines
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

function! ExecuteDiff()
  "Only do a diff when it is a file we are editing, not just a buffer
  if !filereadable(bufname('%'))
    return
  end

  let var=system('git ls-files ' . bufname('%') . ' --error-unmatch')
  if v:shell_error != 0
    return 1
  endif


  ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';
  let file1 = expand('%')
  let file2 = '/tmp/' . substitute(file1, '/', '', 'g') . 'funny'
  silent exec 'write! ' . file2

  let command = "ruby changedlines '" . file1 . "', '" . file2 . "'"
  exec command
endfunction

function! ColourEverything()
  if !filereadable(bufname('%'))
    return 1
  end

  let var=system('git ls-files ' . bufname('%') . ' --error-unmatch')
  if v:shell_error != 0
    return 1
  endif

  call HighlightAllLines()
endfunction

function! GetSigns()
  redir => out
  sil! exec 'sign place'
  redir END
  return out
endfunction

augroup diffing
    autocmd!

    "Note - autocommands on BufWritePost will not be executed on this file
    "because it gets reloaded on each write
    au BufWritePost * :call ColourEverything()
    au BufWinEnter * :call InitializeBuffer()
    autocmd CursorMoved * :call ExecuteDiff()
    autocmd CursorMovedI * :call ExecuteDiff()
augroup END

function! InitializeBuffer()
  let b:signs = {}

  highlight new ctermbg=52 guibg=52
  call DefineSign('new', 'new')

  call ColourEverything()
endfunction
function! DefineSign(name, hlname)
  execute 'sign define ' . a:name . ' linehl=' . a:hlname

  let dict = "{ 'linehl': " . string(a:hlname) . ", 'lines': []}"
  execute 'let b:signs.' . a:name . ' =  ' . dict
endfunction

function! PlaceSign(line_no, hl, filename)
  "TODO: Come up with unique sign numbers = also, probably doesn't need
  "filename
  execute 'sign place ' . a:line_no . ' name=' . a:hl . ' line=' . a:line_no . ' file=' . a:filename
  execute 'let b:signs.' . a:hl . '.lines = b:signs.' . a:hl . '.lines + [' . a:line_no . ']'
endfunction

