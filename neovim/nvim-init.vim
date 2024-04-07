" To use this, make `~/.config/nvim/init.vim` a link to this file
" mkdir -p ~/.config/nvim; ln -sf $(realpath nvim-init.vim) ~/.config/nvim/init.vim

" For this plugins section to work, install vim-plug via the
" instructions at: https://github.com/junegunn/vim-plug#installation
" Then install the plugins by launching nvim and running :PlugInstall
" Start plugins section
call plug#begin('~/.config/nvim/plugged')
Plug 'altercation/vim-colors-solarized'
Plug 'morhetz/gruvbox'
Plug 'crusoexia/vim-monokai'
Plug 'joshdick/onedark.vim'
Plug 'github/copilot.vim'
Plug 'dense-analysis/ale'
call plug#end()
let g:python3_host_prog = expand('~/.virtualenvs/neovim-plugins/bin/python')
let g:ale_linters = {
    \ 'python': ['flake8'],
    \ }
let g:ale_python_flake8_executable = expand('~/.virtualenvs/neovim-plugins/bin/flake8')
let g:ale_python_flake8_options = '--config ' . expand('~/repos/jasper-tms/shell-configs/neovim/flake8-settings')

" End plugins section

" Set colorscheme
"let g:solarized_termcolors=256
"colorscheme solarized
colorscheme gruvbox | set bg=dark
"colorscheme monokai
"colorscheme onedark

" General settings
filetype plugin indent on
syntax on
set number
set hlsearch
set incsearch
set laststatus=1
set ruler
" Allow text selection via mouse
set mouse=a
" Use system clipboard
set clipboard+=unnamedplus

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

" Hard wrap lines after 79 characters in python files
autocmd Filetype python setlocal textwidth=79

