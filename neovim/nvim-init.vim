" To use this, make `~/.config/nvim/init.vim` a link to this file
" mkdir -p ~/.config/nvim; ln -sf "$(realpath nvim-init.vim)" ~/.config/nvim/init.vim


" --- General settings -------------------------------------------------------
set number
set hlsearch
set incsearch
set ignorecase
set smartcase
set laststatus=1
set ruler
" Allow text selection via mouse
set mouse=a
" Indentation
set tabstop=4
set shiftwidth=4
set expandtab
" Disable unused language providers to speed up startup
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0
let g:loaded_python_provider = 0 | " This disables python2, not python3


" --- Filetype-specific settings ----------------------------------------------
augroup init_ftypes
  autocmd!
  " Start new Python files with a shebang
  autocmd BufNewFile *.py call append(0, ['#!/usr/bin/env python3', ''])
  " Hard wrap lines after 79 characters in python files
  autocmd FileType python setlocal textwidth=79
  " Hard wrap markdown files by default (run :HardWrap to toggle off).
  " Remove the 'l' flag markdown's ftplugin adds, so lines already longer
  " than textwidth get wrapped as you keep typing on them.
  autocmd FileType markdown setlocal textwidth=79 formatoptions-=l
  " Write actual tab characters, not 4 spaces, in .tsv files
  autocmd BufRead,BufNewFile *.tsv setlocal noexpandtab
augroup END


" --- Hard wrap toggle --------------------------------------------------------
" Hard wrapping (auto-inserting line breaks at a column width as you type)
" is off by default for most filetypes, but on by default for markdown (see
" the filetype-specific settings above). Run :HardWrap in a buffer to toggle
" it: on at 79 columns, or off again.
"
" Turning hard wrap off is remembered per file, so the file opens unwrapped
" next time too. Each remembered file gets an empty marker file in
" ~/.local/state/nvim/no-hard-wrap/ named after the file's absolute path,
" percent-encoded so it's a valid, unambiguous filename ('%' becomes '%25' and
" '/' becomes '%2F'). This makes checking, remembering, and forgetting a file
" each a single filesystem operation regardless of how many files are
" remembered. Remembered settings don't follow a file if it is moved or
" renamed.
let s:no_hard_wrap_directory = stdpath('state') . '/no-hard-wrap'
" Most filesystems (including APFS and ext4) cap filenames at 255 bytes
let s:maximum_filename_bytes = 255

function! s:NoHardWrapMarkerPath(file_path) abort
  let encoded = substitute(a:file_path, '%', '%25', 'g')
  let encoded = substitute(encoded, '/', '%2F', 'g')
  " Keep only the end of names too long for the filesystem. Two deep paths
  " sharing the same last ~255 bytes would then share a marker, which is rare
  " enough to accept. Trim whole characters (not bytes) so a multibyte
  " character never gets split into an invalid filename.
  if strlen(encoded) > s:maximum_filename_bytes
    let encoded = strcharpart(encoded, strchars(encoded) - s:maximum_filename_bytes)
    while strlen(encoded) > s:maximum_filename_bytes
      let encoded = strcharpart(encoded, 1)
    endwhile
  endif
  return s:no_hard_wrap_directory . '/' . encoded
endfunction

function! s:CurrentFilePath() abort
  " Empty for buffers that aren't backed by a file (e.g. unnamed buffers)
  if empty(expand('%')) || !empty(&buftype)
    return ''
  endif
  return resolve(expand('%:p'))
endfunction

function! s:ToggleHardWrap() abort
  let file_path = s:CurrentFilePath()
  if &l:textwidth == 0
    setlocal textwidth=79
    " Remove the 'l' flag some ftplugins (e.g. markdown's) add, so lines
    " already longer than textwidth get wrapped as you keep typing on them.
    setlocal formatoptions-=l
    if !empty(file_path)
      call delete(s:NoHardWrapMarkerPath(file_path))
    endif
    echo 'Hard wrap on (textwidth=79)'
  else
    setlocal textwidth=0
    if empty(file_path)
      echo 'Hard wrap off'
      return
    endif
    call mkdir(s:no_hard_wrap_directory, 'p')
    call writefile([], s:NoHardWrapMarkerPath(file_path))
    echo 'Hard wrap off (remembered for this file)'
  endif
endfunction
command! HardWrap call s:ToggleHardWrap()

function! s:NotifyRememberedNoHardWrap(timer_id) abort
  echomsg 'Hard wrap off (remembered for this file)'
endfunction

" Runs after the filetype-specific settings above (autocommands run in the
" order they were defined), so it overrides their default textwidth.
function! s:ApplyRememberedNoHardWrap() abort
  " Only files whose filetype hard wraps by default need overriding
  if &l:textwidth == 0
    return
  endif
  let file_path = s:CurrentFilePath()
  if !empty(file_path) && filereadable(s:NoHardWrapMarkerPath(file_path))
    setlocal textwidth=0
    " Deferred until loading finishes, since the '"file" 12L, 340B' message
    " printed while loading would otherwise overwrite this notice
    call timer_start(0, function('s:NotifyRememberedNoHardWrap'))
  endif
endfunction

augroup remembered_no_hard_wrap
  autocmd!
  autocmd FileType * call s:ApplyRememberedNoHardWrap()
augroup END


" --- Clipboard --------------------------------------------------------------
" Terminal.app doesn't implement XTGETTCAP, so neovim's OSC 52 capability
" probe gets drawn as literal text (`+q4D73`) over the first line. Must be set
" before the clipboard provider initializes.
let g:termfeatures = extend(get(g:, 'termfeatures', {}), {'osc52': v:false})

if !empty($SSH_CLIENT) || !empty($SSH_TTY)
  " Over ssh, the system clipboard isn't reachable — leave it unset so yanks
  " stay in vim registers instead of hanging waiting for a clipboard provider.
  set clipboard=
else
  set clipboard+=unnamedplus
endif
" Map Ctrl+C to yank-to-system-clipboard on non-mac systems.
" On Mac, Cmd+C is handled by the terminal itself; <D-c> "+y didn't work in
" testing, so just use plain `y` on Mac (combined with clipboard=unnamedplus).
if !has('mac')
  nnoremap <C-c> "+y
  vnoremap <C-c> "+y
endif


" --- Plugins -----------------------------------------------------------------
" For this plugins section to work, install vim-plug via the
" instructions at: https://github.com/junegunn/vim-plug#installation
" Then install the plugins by launching nvim and running :PlugInstall
call plug#begin(stdpath('data') . '/plugged')
Plug 'morhetz/gruvbox'
" `'on': []` defers loading until plug#load() is called manually (below).
Plug 'github/copilot.vim', { 'on': [] }
" `'for': 'python'` lazy-loads the linter plugin only when a python buffer is opened.
Plug 'dense-analysis/ale', { 'for': 'python' }
call plug#end()
" Load copilot the first time we enter insert mode, then never re-trigger.
autocmd InsertEnter * ++once call plug#load('copilot.vim')


" --- Colorscheme ------------------------------------------------------------
set bg=dark
colorscheme gruvbox


" --- Linting with ruff ------------------------------------------------------
let g:ale_linters = {
    \ 'python': ['ruff'],
    \ }
" ruff discovers config from the file's project (pyproject.toml / ruff.toml)
" or falls back to ~/.config/ruff/ruff.toml — symlink that to neovim/ruff.toml
" in this repo: ln -sf $(realpath neovim/ruff.toml) ~/.config/ruff/ruff.toml
" ruff is installed as a standalone CLI via `uv tool install ruff`.
let g:ale_python_ruff_executable = expand('~/.local/bin/ruff')


" --- Auto-formatting on save with ruff --------------------------------------
let g:ale_fixers = {
    \ 'python': ['ruff_format'],
    \ }
let g:ale_python_ruff_format_executable = expand('~/.local/bin/ruff')
" Format on save is opt-in. Enable per-session by launching nvim with
" RUFF_FORMAT_ON_SAVE=1, or per-shell with `export RUFF_FORMAT_ON_SAVE=1`.
" Unset or '0' = no format on save; any other value = format on save.
let g:ale_fix_on_save = (empty($RUFF_FORMAT_ON_SAVE) || $RUFF_FORMAT_ON_SAVE ==# '0') ? 0 : 1


" --- Navigation shortcuts to find linter messages ---------------------------
" ]A / [A jump to the next/prev lint diagnostic, wrapping at file ends.
nmap ]A <Plug>(ale_next_wrap)
nmap [A <Plug>(ale_previous_wrap)

" ]a / [a do the same but skip diagnostics whose code is in s:ale_skip_codes
" (e.g. E501 line-too-long is noisy enough that we'd rather skip past it
" while still seeing it highlighted in the gutter).
let s:ale_skip_codes = ['E501']
function! s:ALEJumpSkipCodes(direction) abort
  let l:items = filter(copy(ale#engine#GetLoclist(bufnr(''))),
        \ 'index(s:ale_skip_codes, get(v:val, "code", "")) == -1')
  if empty(l:items)
    return
  endif
  let l:line = line('.')
  let l:col = col('.')
  if a:direction ==# 'next'
    for l:item in l:items
      if l:item.lnum > l:line || (l:item.lnum == l:line && l:item.col > l:col)
        call cursor(l:item.lnum, l:item.col)
        return
      endif
    endfor
    " Wrap to the first diagnostic if we're past the last one.
    call cursor(l:items[0].lnum, l:items[0].col)
  else
    for l:item in reverse(copy(l:items))
      if l:item.lnum < l:line || (l:item.lnum == l:line && l:item.col < l:col)
        call cursor(l:item.lnum, l:item.col)
        return
      endif
    endfor
    " Wrap to the last diagnostic if we're before the first one.
    call cursor(l:items[-1].lnum, l:items[-1].col)
  endif
endfunction
nnoremap <silent> ]a :call <SID>ALEJumpSkipCodes('next')<CR>
nnoremap <silent> [a :call <SID>ALEJumpSkipCodes('prev')<CR>
