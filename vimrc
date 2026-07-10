filetype plugin indent on
syntax on
colorscheme default
set tabstop=4
set shiftwidth=4
set expandtab
set number
set hlsearch
set incsearch
set ruler
set clipboard=exclude:.*

autocmd BufNewFile *.py call append(0, ['#!/usr/bin/env python3', ''])
autocmd Filetype python setlocal textwidth=79
autocmd BufRead,BufNewFile *.tsv setlocal noexpandtab

" Hard wrapping (auto-inserting line breaks at a column width as you type)
" is off by default, including for markdown. Run :HardWrap in a buffer to
" turn it on at 72 columns; run it again to turn it back off.
function! s:ToggleHardWrap() abort
  if &l:textwidth == 0
    setlocal textwidth=72
    " Remove the 'l' flag some ftplugins (e.g. markdown's) add, so lines
    " already longer than textwidth get wrapped as you keep typing on them.
    setlocal formatoptions-=l
    echo 'Hard wrap on (textwidth=72)'
  else
    setlocal textwidth=0
    echo 'Hard wrap off'
  endif
endfunction
command! HardWrap call s:ToggleHardWrap()
