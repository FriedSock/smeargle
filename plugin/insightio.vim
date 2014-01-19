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
  let b:groups = {}
  let b:signs = {}
  let b:id = 0

  highlight new ctermbg=52 guibg=52
  call DefineSign('new', 'new')

  call ColourEverything()
endfunction
function! DefineSign(name, hlname)
  execute 'sign define ' . a:name . ' linehl=' . a:hlname

  let dict = "{ 'linehl': " . string(a:hlname) . ", 'lines': {}}"
  execute 'let b:groups.' . a:name . ' =  ' . dict
endfunction

function! PlaceSign(line_no, hl, filename)
  "TODO: Probably dont need filename
  let id = string(GetNewID())
  execute 'sign place ' . id . ' name=' . a:hl . ' line=' . a:line_no . ' file=' . a:filename
  execute 'let b:groups.' . a:hl . '.lines.'. a:line_no . '= {}'

  let sign_entry = "{'id': " . id . ", 'group': " . string(a:hl) ." }"
  execute 'let b:signs.' . a:line_no . ' = ' . sign_entry
endfunction

function! UnplaceSign(line)
  execute 'let id = b:signs.' . a:line . '.id'
  execute 'sign unplace ' . id
  execute 'let group = b:signs.' . a:line . '.group'
  execute 'unlet b:signs.' . a:line
  execute 'unlet b:groups.' . group . '.lines.' . a:line
endfunction
function! GetNewID()
  let b:id = b:id + 1
  return b:id
endfunction


highlight col231 ctermbg=231  guibg=231
highlight col232 ctermbg=232  guibg=232
highlight col233 ctermbg=233  guibg=233
highlight col234 ctermbg=234  guibg=234
highlight col235 ctermbg=235  guibg=235
highlight col235 ctermbg=235  guibg=235
highlight col236 ctermbg=236  guibg=236
highlight col237 ctermbg=237  guibg=237

