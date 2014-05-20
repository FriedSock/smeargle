let s:dir = "/" . join(split(expand("<sfile>"), "/")[0:-2], "/")
ruby $smeargle_dir = VIM::evaluate('s:dir')
ruby load File.join($smeargle_dir, 'helper.rb');
ruby load File.join($smeargle_dir, 'puts.rb');


function! DefineSigns()
  execute 'sign define c' . bufnr('%') . 'col231 linehl=231'
  execute 'sign define c' . bufnr('%') . 'col232 linehl=232'
  execute 'sign define c' . bufnr('%') . 'col233 linehl=233'
  execute 'sign define c' . bufnr('%') . 'col234 linehl=234'
  execute 'sign define c' . bufnr('%') . 'col235 linehl=235'
  execute 'sign define c' . bufnr('%') . 'col236 linehl=236'
  execute 'sign define c' . bufnr('%') . 'col237 linehl=237'
  execute 'sign define c' . bufnr('%') . 'col238 linehl=238'
  execute 'sign define c' . bufnr('%') . 'new linehl=new'
endfunction

function! DefineHighlights()
  highlight Visual cterm=reverse gui=reverse
  highlight CursorLine cterm=reverse gui=reverse
  highlight CursorColumn cterm=reverse gui=reverse

  execute 'highlight c' . bufnr('%') . 'col231 ctermbg=231  guibg=#ffffff'
  execute 'highlight c' . bufnr('%') . 'col232 ctermbg=232  guibg=#080808'
  execute 'highlight c' . bufnr('%') . 'col233 ctermbg=233  guibg=#121212'
  execute 'highlight c' . bufnr('%') . 'col234 ctermbg=234  guibg=#1c1c1c'
  execute 'highlight c' . bufnr('%') . 'col235 ctermbg=235  guibg=#262626'
  execute 'highlight c' . bufnr('%') . 'col236 ctermbg=236  guibg=#303030'
  execute 'highlight c' . bufnr('%') . 'col237 ctermbg=237  guibg=#3a3a3a'
  execute 'highlight c' . bufnr('%') . 'col238 ctermbg=238  guibg=#444444'
  execute 'highlight c' . bufnr('%') . 'new ctermbg=23 guibg=#005f5f'
endfunction

"Unfortunately it takes 7ms to unplace a specific sign using sign unplace (and we can't unplace
"them all because of multple cuffers). So the best solution is to just set all
"of the highlights for the existing signs to be that of the initial terminal
"backround colour.
function! ClearHighlights()
  let c = 231
  while c <= 238
    let command = 'highlight c' . bufnr('%') . 'col' . string(c) . ' ctermbg=' . s:ctermbg . ' guibg=' . s:guibg
    execute command
    let c += 1
  endwhile
  let command = 'highlight c'. bufnr('%') . 'new ctermbg=' . s:ctermbg . ' guibg=' . s:guibg
  execute command
  let command =  'highlight Visual cterm=' . s:visual_term . ' gui=' . s:visual_gui
  execute command
  let command = 'highlight CursorLine cterm=' . s:cursorline_term . ' gui=' . s:cursorline_gui
  execute command
  let command = 'highlight CursorColumn cterm=' . s:cursorcolumn_term . ' gui=' . s:cursorcolumn_gui
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
if match(s:ctermbg, '\v ctermbg\=') > -1
  let s:ctermbg = split(matchstr(s:ctermbg, '\v ctermbg\=(\S*)'), '=')[-1]
else
  let s:ctermbg = 'NONE'
end

redir => s:guibg | silent hi Normal | redir END
if match(s:guibg, '\v guibg\=') > -1
  let s:guibg = split(matchstr(s:guibg, '\v guibg\=(\S*)'), '=')[-1]
else
  let s:guibg = 'NONE'
end

redir => s:visual_term | silent hi Visual | redir END
if match(s:visual_term, '\v cterm\=') > -1
  let s:visual_term = split(matchstr(s:visual_term, '\v cterm\=(\S*)'), '=')[-1]
else
  let s:visual_term = 'NONE'
endif

redir => s:cursorline_term | silent hi CursorLine | redir END
if match(s:cursorline_term, '\v cterm\=') > -1
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

redir => s:visual_gui | silent hi Visual | redir END
if match(s:visual_gui, '\v gui\=') > -1
  let s:visual_gui = split(matchstr(s:visual_gui, '\v gui\=(\S*)'), '=')[-1]
else
  let s:visual_gui = 'NONE'
endif

redir => s:cursorline_gui | silent hi CursorLine | redir END
if match(s:cursorline_gui, '\v gui\=') > -1
  let s:cursorline_gui = split(matchstr(s:cursorline_gui, '\v gui\=(\S*)'), '=')[-1]
else
  let s:cursorline_gui = 'NONE'
endif

redir => s:cursorcolumn_gui | silent hi CursorColumn | redir END
if match(s:cursorcolumn_gui, '\v gui\=') > -1
  let s:cursorcolumn_gui = split(matchstr(s:cursorcolumn_gui, '\v gui\=(\S*)'), '=')[-1]
else
  let s:cursorcolumn_gui = 'NONE'
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
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  call DefineHighlights()
  if b:colouring_scheme ==# 'jenks'
    call ClearColourScheme()
    return 0
  endif
  let b:colouring_scheme = 'jenks'
  ruby highlight_lines :reverse => true
  ruby refresh
  call ResetTimeout('jenks')
  normal jk
endfunction


function! ToggleHeat()
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  call DefineHighlights()
  if b:colouring_scheme ==# 'heat'
    call ClearColourScheme()
    return 0
  endif
  let b:colouring_scheme = 'heat'
  ruby highlight_lines :type => :heat, :reverse => true
  ruby refresh
  call ResetTimeout('heat')
  normal jk
endfunction

function! ResetTimeout(name)
  if exists('b:colour_timeout') && b:colour_timeout == 1
    echom a:name .  ' colouring is not ready yet'
    let b:colour_timeout = 0
    let b:colouring_scheme = ''
    call ClearColourScheme()
  end
endfunction

function! ToggleAuthor()
  if !exists('b:colourable') || !b:colourable
    return 0
  endif
  call DefineHighlights()
  if b:colouring_scheme ==# 'author'
    call ClearColourScheme()
    return 0
  endif
  let b:colouring_scheme = 'author'
  ruby highlight_lines :type => :author, :reverse => true
  ruby refresh
  call ResetTimeout('author')
  normal jk
endfunction

function! ExecuteDiff()
  "Only do a diff when it is a file we are editing, not just a buffer
  if !exists('b:colourable') || !b:colourable || b:colouring_scheme ==# ''
    return 0
  endif

  let file1 = b:original_buffer_name
  let file2 = '/tmp/' . substitute(file1, '/', '', 'g') . 'asdf232'

  let preserved_scheme = b:colouring_scheme
  silent exec 'write! ' . file2
  let b:colouring_scheme = preserved_scheme

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

  call DefineHighlights()

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

  ruby initialize_buffer
  normal jk
  call HighlightAllLines()
endfunction

function! Colourable()
  if !filereadable(bufname('%'))
    return 0
  endif

  let splitted_fullname = split(expand('%:p'), '/')
  let filename = splitted_fullname[-1]
  let dir = '/' . join(splitted_fullname[0:-2], '/')

  call system('cd ' . dir . '; git ls-files ' . filename . ' --error-unmatch')
  if v:shell_error != 0
    return 0
  endif

  call system('cd ' . dir . '; git blame ' . filename)
  if v:shell_error != 0
    return 0
  endif
  return 1
endfunction

function! MoveWrapper()
  if !exists('b:colouring_scheme') || b:colouring_scheme ==# ''
    return 0
  else
    call ExecuteDiff()
  endif
endfunction
