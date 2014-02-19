ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';
ruby load '~/.vim/bundle/git-off-my-lawn/plugin/puts.rb';

highlight Visual cterm=reverse
highlight CursorLine cterm=reverse
highlight CursorColumn cterm=reverse

highlight col231 ctermbg=231  guibg=231
sign define col231 linehl=231
highlight col232 ctermbg=232  guibg=232
sign define col232 linehl=232
highlight col233 ctermbg=233  guibg=233
sign define col233 linehl=233
highlight col234 ctermbg=234  guibg=234
sign define col234 linehl=234
highlight col235 ctermbg=235  guibg=235
sign define col235 linehl=235
highlight col236 ctermbg=236  guibg=236
sign define col236 linehl=236
highlight col237 ctermbg=237  guibg=237
sign define col237 linehl=237
highlight col238 ctermbg=238  guibg=238
sign define col238 linehl=238
sign define name=new linehl=new

function! OpenWindow()
  ruby open_window
endfunction

function! HighlightAllLines()
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :reverse => true
endfunction

function! HighlightAllLinesLinear()
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :type => :linear, :reverse => true
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
  if !exists('b:colourable') || !b:colourable
    return 0
  endif

  ruby load '~/.vim/bundle/git-off-my-lawn/plugin/helper.rb';
  let file1 = b:original_buffer_name
  let file2 = '/tmp/' . substitute(file1, '/', '', 'g') . 'asdf232'
  silent exec 'write! ' . file2

  let command = "ruby changedlines '" . file1 . "', '" . file2 . "'"
  exec command
endfunction

augroup diffing
    autocmd!

    "Note - autocommands on BufWritePost will not be executed on this file
    "because it gets reloaded on each write
    au BufWritePost * :call ResetState()
    au BufWinEnter * :call InitializeBuffer()
    autocmd CursorMoved * :call MoveWrapper()
    autocmd CursorMovedI * :call MoveWrapper()
augroup END

function! InitializeBuffer()
  "Only do a diff when it is a file we are editing, not just a buffer
  let b:colourable = Colourable()

  if !b:colourable
    return 0
  end

  ruby initialize_buffer

  highlight new ctermbg=23 guibg=52

  call HighlightAllLines()
endfunction

function! ResetState()
  if !b:colourable
    return 0
  end

  ruby mark_signs_for_deletion
  "TODO: something more sophisticated
  ruby initialize_buffer
  ruby delete_signs
  call HighlightAllLines()
endfunction

function! Colourable()
  if !filereadable(bufname('%'))
    return 0
  endif
  let var=system('git ls-files ' . bufname('%') . ' --error-unmatch')
  if v:shell_error != 0
    return 0
  endif
  return 1
endfunction

map <leader>l :call HighlightAllLinesLinear()<cr>
map <leader>c :call HighlightAllLines()<cr>

map <leader>k :call ShowKey()<cr>
function! ShowKey()

  "TODO - toggling
  call SplitVertical()

endfunction

function! SplitVertical()
  let new_name = bufname('%') . '-key'
  badd new_name

  split
  "TODO: Remove magic number
  resize 3

  exec 'edit ' . new_name
  set bt=nofile
  setlocal nonumber
  setlocal listchars=
  setlocal statusline=The\ Key
  ruby generate_key
endfunction

function! MoveWrapper()
  call ExecuteDiff()
endfunction

