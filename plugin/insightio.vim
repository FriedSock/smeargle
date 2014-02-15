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
  call ResetState()
  ruby highlight_lines :reverse => true
endfunction

function! HighlightAllLinesLinear()
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  call ResetState()
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
  let file1 = expand('%')
  let file2 = '/tmp/' . substitute(file1, '/', '', 'g') . 'funny'
  silent exec 'write! ' . file2

  let command = "ruby changedlines '" . file1 . "', '" . file2 . "'"
  exec command
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
    au BufWritePost * :call HighlightAllLines()
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

  call ResetState()

  ruby initialize_buffer

  highlight new ctermbg=52 guibg=52
  call DefineSign('new', 'new')

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

function! ResetState()
  execute 'sign unplace *'
  let b:groups = {}
  let b:signs = {}
  let b:id = 0
endfunction

map <leader>l :call HighlightAllLinesLinear()<cr>
map <leader>c :call HighlightAllLines()<cr>

map <leader>k :call ShowKey()<cr>
function! ShowKey()

  "TODO - toggling
  call SplitVertical()

endfunction

function! DefineSign(name, hlname)
  execute 'sign define ' . a:name . ' linehl=' . a:hlname

  let dict = "{ 'linehl': " . string(a:hlname) . ", 'ids': {}}"
  execute 'let b:groups.' . a:name . ' =  ' . dict
endfunction

function! PlaceSign(line_no, hl, filename)
  "TODO: Probably dont need filename
  let id = string(GetNewID())
  execute 'sign place ' . id . ' name=' . a:hl . ' line=' . a:line_no . ' file=' . a:filename
  execute 'let b:groups.' . a:hl . '.ids.'. id . '= {}'

  let sign_entry = "{'line': " . a:line_no . ", 'original_line': " . a:line_no  . ", 'group': " . string(a:hl) ." }"
  execute 'let b:signs.' . id . ' = ' . sign_entry
endfunction

"For now, this is only going to be used for unplacing 'new' ie. red signs
function! UnplaceSign(line)
  echom "Unplacing Line: " . a:line
  for e in items(b:signs)
    if string(e[1].line) ==# a:line && string(e[1].group) ==# 'new'
      echom string(e)
      "TODO break
      let id = e[0]
    end
  endfor

  execute 'sign unplace ' . id
  execute 'let group = b:signs.' . id . '.group'
  execute 'unlet b:signs.' . id
  execute 'unlet b:groups.' . group . '.ids.' . id
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
  "TODO: calculate where the new line has been added - Could do this in ruby
  call ExecuteDiff()
endfunction

function! ArchiveSign(line)
  for e in items(b:signs)
    if e[1].original_line == a:line
      execute 'sign unplace ' . e[0] . ' file=' . bufname('%')
      return
    end
  endfor
endfunction

function! ReinstateSign(line)
  "Note: Need to move line up, because it was recently moved down to make way
  "for itself
  for e in items(b:signs)
    if e[1].original_line == a:line
      let id = e[0]
      let line = e[1].line - 1
      execute 'let b:signs' . '.' . id . '.line=' . line
      execute 'sign place ' . id . ' name=' . e[1].group . ' line=' . line . ' file=' . bufname('%')
      return
    end
  endfor
endfunction

function! ReinstateSequence(lines)
  let signs = FindSignsByOriginalLine(a:lines)
  echom "SIGNS " . string(signs)
  let original_first_line = a:lines[0]
  for id in signs
    execute 'let si = b:signs.' . id
    if si.original_line == original_first_line
      let first_line = si
    end
  endfor

  for id in signs
    execute 'let si = b:signs.' . id
    echom "si " . string(si)
    echom "first_line " . string(first_line)
    let line_difference  =  si.original_line - first_line.original_line
    let new_line =  first_line.line + line_difference
    execute 'let b:signs.' . id . '.line=' . new_line
    echom 'sign place ' . id . ' name=' . si.group . ' line=' . new_line . ' file=' . bufname('%')
    execute 'sign place ' . id . ' name=' . si.group . ' line=' . new_line . ' file=' . bufname('%')
  endfor
endfunction



