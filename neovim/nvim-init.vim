" To use this, make `~/.config/nvim/init.vim` a link to this file
" mkdir -p ~/.config/nvim; ln -sf $(realpath nvim-init.vim) ~/.config/nvim/init.vim

" Disable unused language providers to speed up startup
let g:loaded_python_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0

" For this plugins section to work, install vim-plug via the
" instructions at: https://github.com/junegunn/vim-plug#installation
" Then install the plugins by launching nvim and running :PlugInstall
" Start plugins section
call plug#begin(stdpath('data') . '/plugged')
Plug 'morhetz/gruvbox'
Plug 'github/copilot.vim', { 'on': [] }
Plug 'dense-analysis/ale', { 'for': 'python' }
call plug#end()
autocmd InsertEnter * ++once call plug#load('copilot.vim')
let s:venvs = !empty($WORKON_HOME) ? $WORKON_HOME : expand('~/.virtualenvs')
let g:python3_host_prog = s:venvs . '/neovim-plugins/bin/python'
let g:ale_linters = {
    \ 'python': ['flake8'],
    \ }
let g:ale_python_flake8_executable = s:venvs . '/neovim-plugins/bin/flake8'
let g:ale_python_flake8_options = '--config ' . fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/flake8-settings'
nmap ]A <Plug>(ale_next_wrap)
nmap [A <Plug>(ale_previous_wrap)
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
    call cursor(l:items[0].lnum, l:items[0].col)
  else
    for l:item in reverse(copy(l:items))
      if l:item.lnum < l:line || (l:item.lnum == l:line && l:item.col < l:col)
        call cursor(l:item.lnum, l:item.col)
        return
      endif
    endfor
    call cursor(l:items[-1].lnum, l:items[-1].col)
  endif
endfunction
nnoremap <silent> ]a :call <SID>ALEJumpSkipCodes('next')<CR>
nnoremap <silent> [a :call <SID>ALEJumpSkipCodes('prev')<CR>


" End plugins section

" Set colorscheme
set bg=dark
colorscheme gruvbox

" General settings
set number
set hlsearch
set incsearch
set laststatus=1
set ruler
" Allow text selection via mouse
set mouse=a
if !empty($SSH_CLIENT) || !empty($SSH_TTY)
  " Give up on using the system clipboard over ssh
  set clipboard=
" Use system clipboard
else
  " When not over ssh, use the system clipboard
  set clipboard+=unnamedplus
endif

" Indentation settings
set tabstop=4
set shiftwidth=4
set expandtab

" Map Ctrl+C to `y` (yank), on non-mac systems
if !has('mac')
  nnoremap <C-c> "+y
  vnoremap <C-c> "+y
endif
" Can't get Cmd+C on mac to work: GPT said to try `<D-c> "+y` but
" that doesn't do it. So just use `y` on Mac to copy to clipboard.

" Filetype-specific settings
augroup jasper_ftypes
  autocmd!
  "   Start new Python files with a shebang
  autocmd BufNewFile *.py call append(0, ['#!/usr/bin/env python3', ''])
  "   Hard wrap lines after 79 characters in python files
  autocmd FileType python setlocal textwidth=79
  "   Actually use tab characters, not 4 spaces, in .tsv files
  autocmd BufRead,BufNewFile *.tsv setlocal noexpandtab
augroup END
