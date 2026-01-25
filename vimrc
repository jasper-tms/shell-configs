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
