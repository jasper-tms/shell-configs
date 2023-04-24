" To use this, make `~/.config/nvim/init.vim` a link to this file

" General settings
filetype plugin indent on
syntax on
colorscheme default
set number
set hlsearch
set incsearch
set ruler
" Allow text selection via mouse
set mouse=a
" Use system clipboard
set clipboard+=unnamedplus

" Indentation settings
set tabstop=4
set shiftwidth=4
set expandtab

" Show trailing whitespace and extra spaces before a tab
set listchars=tab:>-,trail:·
set list


" Map Ctrl+C to `y` (yank), on non-mac systems
if !has('mac')
  nnoremap <C-c> "+y
  vnoremap <C-c> "+y
endif
" Can't get Cmd+C on mac to work: GPT said to try `<D-c> "+y` but
" that doesn't do it. So just use `y` on Mac to copy to clipboard.

" Hard wrap lines after 79 characters in python files
autocmd Filetype python setlocal textwidth=79
