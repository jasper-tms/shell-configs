" To use this, make `~/.config/nvim/init.vim` a link to this file
" mkdir -p ~/.config/nvim; ln -sf $(realpath nvim-init.vim) ~/.config/nvim/init.vim


" --- General settings -------------------------------------------------------
set number
set hlsearch
set incsearch
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
  " Write actual tab characters, not 4 spaces, in .tsv files
  autocmd BufRead,BufNewFile *.tsv setlocal noexpandtab
augroup END


" --- Clipboard --------------------------------------------------------------
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


" --- Python venv discovery --------------------------------------------------
" `s:` is a script-local variable (visible only within this file).
let s:venvs = !empty($WORKON_HOME) ? $WORKON_HOME : expand('~/.virtualenvs')
let g:python3_host_prog = s:venvs . '/neovim-plugins/bin/python'


" --- Linting with ruff ------------------------------------------------------
let g:ale_linters = {
    \ 'python': ['ruff'],
    \ }
" ruff discovers config from the file's project (pyproject.toml / ruff.toml)
" or falls back to ~/.config/ruff/ruff.toml — symlink that to neovim/ruff.toml
" in this repo: ln -sf $(realpath neovim/ruff.toml) ~/.config/ruff/ruff.toml
let g:ale_python_ruff_executable = s:venvs . '/neovim-plugins/bin/ruff'


" --- Auto-formatting on save with ruff --------------------------------------
let g:ale_fixers = {
    \ 'python': ['ruff_format'],
    \ }
let g:ale_python_ruff_format_executable = s:venvs . '/neovim-plugins/bin/ruff'
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
