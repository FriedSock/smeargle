let s:dir = "/" . join(split(expand("<sfile>"), "/")[0:-2], "/")
ruby $dir = VIM::evaluate('s:dir')
ruby load File.join($dir, 'helper.rb');
ruby load File.join($dir, 'puts.rb');

sign define col231 linehl=231
sign define col232 linehl=232
sign define col233 linehl=233
sign define col234 linehl=234
sign define col235 linehl=235
sign define col236 linehl=236
sign define col237 linehl=237
sign define col238 linehl=238
sign define name=new linehl=new

function! DefineHighlights()
  highlight Visual cterm=reverse
  highlight CursorLine cterm=reverse
  highlight CursorColumn cterm=reverse

  highlight col231 ctermbg=231  guibg=231
  highlight col232 ctermbg=232  guibg=232
  highlight col233 ctermbg=233  guibg=233
  highlight col234 ctermbg=234  guibg=234
  highlight col235 ctermbg=235  guibg=235
  highlight col236 ctermbg=236  guibg=236
  highlight col237 ctermbg=237  guibg=237
  highlight col238 ctermbg=238  guibg=238
  highlight new ctermbg=23 guibg=52
endfunction

"Unfortunately it takes 7ms to unplace a specific sign using sign unplace (and we can't unplace
"them all because of multple cuffers). So the best solution is to just set all
"of the highlights for the existing signs to be that of the initial terminal
"backround colour.
function! ClearHighlights()
  let c = 231
  while c <= 238
    let command = 'highlight col' . string(c) . ' ctermbg=' . s:ctermbg
    execute command
    let c += 1
  endwhile
  let command = 'highlight new ctermbg=' . s:ctermbg
  execute command
  let command =  'highlight Visual cterm=' . s:visual_term
  execute command
  let command = 'highlight CursorLine cterm=' . s:cursorline_term
  execute command
  let command = 'highlight CursorColumn cterm=' . s:cursorcolumn_term
  execute command
endfunction

if !exists('g:smeargle_heat_map')   | let g:smeargle_heat_map   = '<leader>h' | en
if !exists('g:smeargle_jenks_map')  | let g:smeargle_jenks_map  = '<leader>j' | en
if !exists('g:smeargle_author_map') | let g:smeargle_author_map = '<leader>a' | en
if !exists('g:smeargle_clear_map')  | let g:smeargle_clear_map  = '<leader>c' | en

if !exists('g:smeargle_colour_timeout')  | let g:smeargle_colour_timeout  = 5 | en

redir => s:existing_mapping | silent map <leader>h | redir END
if match(s:existing_mapping, 'No mapping found') && g:smeargle_heat_map != ''
      \ && !hasmapto(':SmeargleHeatToggle')
  execute 'nnoremap <silent>' . g:smeargle_heat_map . ' :SmeargleHeatToggle<cr>'
endif

redir => s:existing_mapping | silent map <leader>j | redir END
if match(s:existing_mapping, 'No mapping found') && g:smeargle_jenks_map != ''
      \ && !hasmapto(':SmeargleJenksToggle')
  execute 'nnoremap <silent>' . g:smeargle_jenks_map . ' :SmeargleJenksToggle<cr>'
endif

redir => s:existing_mapping | silent map <leader>a | redir END
if match(s:existing_mapping, 'No mapping found') && g:smeargle_author_map != ''
      \ && !hasmapto(':SmeargleAuthorToggle')
  execute 'nnoremap <silent>' . g:smeargle_author_map . ' :SmeargleAuthorToggle<cr>'
endif

redir => s:existing_mapping | silent map <leader>c | redir END
if match(s:existing_mapping, 'No mapping found') && g:smeargle_clear_map != ''
      \ && !hasmapto(':SmeargleClear')
  execute 'nnoremap <silent>' . g:smeargle_clear_map . ' :SmeargleClear<cr>'
endif

"Save all of the existing colour settings that we will change for any schemes,
"these will then be reset when the schemes are toggled off.
redir => s:ctermbg | silent hi Normal | redir END
let s:ctermbg = split(matchstr(s:ctermbg, '\v ctermbg\=(\S*)'), '=')[-1]

redir => s:visual_term | silent hi Visual | redir END
if match(s:visual_term, '\v cterm\=') > -1
  let s:visual_term = split(matchstr(s:visual_term, '\v cterm\=(\S*)'), '=')[-1]
else
  let s:visual_term = 'NONE'
endif

redir => s:cursorline_term | silent hi CursorLine | redir END
if match(s:cursorline_term, '\v cterm\=') > -1
  echom string(matchstr(s:cursorline_term, '\v cterm\=(\S*)'))
  let s:cursorline_term = split(matchstr(s:cursorline_term, '\v cterm\=(\S*)'), '=')[-1]
else
  let s:cursorline_term = 'NONE'
endif

redir => s:cursorcolumn_term | silent hi CursorColumn | redir END
if match(s:cursorcolumn_term, '\v cterm\=') > -1
  let s:cursorcolumn_term = split(matchstr(s:cursorcolumn_term, '\v cterm\=(\S*)'), '=')[-1]
else
  let s:cursorcolumn_term = 'NONE'
endif

command! -bar SmeargleHeatToggle call ToggleHeat()
command! -bar SmeargleJenksToggle call ToggleJenks()
command! -bar SmeargleAuthorToggle call ToggleAuthor()
command! -bar SmeargleClear call ClearColourScheme()

function! HighlightAllLines()
  let scheme = b:colouring_scheme
  let b:colouring_scheme = ''
  if scheme ==# 'jenks'
    call ToggleJenks()
  elseif scheme ==# 'heat'
    call ToggleHeat()
  elseif scheme ==# 'author'
    call ToggleAuthor()
  endif
endfunction

function! ClearColourScheme()
  let b:colouring_scheme = ''
  call ClearHighlights()
endfunction

function! ToggleJenks()
  call DefineHighlights()
  if b:colouring_scheme ==# 'jenks'
    call ClearColourScheme()
    return 0
  endif
  let b:colouring_scheme = 'jenks'
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :reverse => true
  call ResetTimeout('jenks')
  let preserved_scheme = b:colouring_scheme
  call ExecuteDiff(0)
  let b:colouring_scheme = preserved_scheme
endfunction


function! ToggleHeat()
  call DefineHighlights()
  if b:colouring_scheme ==# 'heat'
    call ClearColourScheme()
    return 0
  endif
  let b:colouring_scheme = 'heat'
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :type => :heat, :reverse => true
  call ResetTimeout('heat')
  let preserved_scheme = b:colouring_scheme
  call ExecuteDiff(0)
  let b:colouring_scheme = preserved_scheme
endfunction

function! ResetTimeout(name)
  if exists('b:colour_timeout') && b:colour_timeout == 1
    echom a:name .  ' colouring is not ready yet'
    let b:colour_timeout = 0
    let b:colouring_scheme = ''
  end
endfunction

function! ToggleAuthor()
  call DefineHighlights()
  if b:colouring_scheme ==# 'author'
    call ClearColourScheme()
    return 0
  endif
  let b:colouring_scheme = 'author'
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  ruby highlight_lines :type => :author, :reverse => true
  call ResetTimeout('author')
  call ExecuteDiff(0)
endfunction

function! ExecuteDiff(nowrite)
  "Only do a diff when it is a file we are editing, not just a buffer
  if !exists('b:colourable') || !b:colourable || b:colouring_scheme ==# ''
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

  if (!exists('g:smeargle_colouring_scheme'))
    let b:colouring_scheme = ''
  else
    let b:colouring_scheme = g:smeargle_colouring_scheme
  endif

  ruby initialize_buffer

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
