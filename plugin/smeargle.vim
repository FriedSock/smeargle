let s:dir = "/" . join(split(expand("<sfile>"), "/")[0:-2], "/")
ruby $dir = VIM::evaluate('s:dir')
ruby load File.join($dir, 'helper.rb');
ruby load File.join($dir, 'puts.rb');

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


map <leader>l :SmeargleHeatToggle<cr>
map <leader>c :SmeargleJenksToggle<cr>
map <leader>a :SmeargleAuthorToggle<cr>

command! -bar SmeargleHeatToggle call HighlightAllLinesHeat()
command! -bar SmeargleJenksToggle call HighlightAllLinesJenks()
command! -bar SmeargleAuthorToggle call HighlightAllLinesAuthor()

function! HighlightAllLines()
  if b:colouring_scheme ==# 'jenks'
    call HighlightAllLinesJenks()
  elseif b:colouring_scheme ==# 'heat'
    call HighlightAllLinesHeat()
  elseif b:colouring_scheme ==# 'author'
    call HighlightAllLinesAuthor()
  endif
endfunction

function! HighlightAllLinesJenks()
  let b:colouring_scheme = 'jenks'
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :reverse => true
  call ExecuteDiff(1)
endfunction


function! HighlightAllLinesHeat()
  let b:colouring_scheme = 'heat'
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :type => :linear, :reverse => true
  call ExecuteDiff(1)
endfunction

function! HighlightAllLinesAuthor()
  let b:colouring_scheme = 'author'
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :type => :author, :reverse => true
  call ExecuteDiff(1)
endfunction

function! ExecuteDiff(nowrite)
  "Only do a diff when it is a file we are editing, not just a buffer
  if !exists('b:colourable') || !b:colourable
    return 0
  endif

  let file1 = b:original_buffer_name
  let file2 = '/tmp/' . substitute(file1, '/', '', 'g') . 'asdf232'
  if a:nowrite
    let b:nowrite = 1
  endif
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

  let b:nowrite = 0

  if (!exists('g:git_colouring_scheme'))
    let b:colouring_scheme = ''
  else
    let b:colouring_scheme = g:git_colouring_scheme
  endif

  ruby initialize_buffer

  highlight new ctermbg=23 guibg=52

  call HighlightAllLines()
endfunction

function! ResetState()
  if !b:colourable
    return 0
  end

  if b:nowrite == 1
    let b:nowrite = 0
    return 0
  end

  ruby initialize_buffer
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

function! MoveWrapper()
  if !exists('b:colouring_scheme') || b:colouring_scheme ==# ''
    return 0
  else
    call ExecuteDiff(0)
  endif
endfunction
