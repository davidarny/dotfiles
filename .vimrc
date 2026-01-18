if empty(glob('~/.vim/autoload/plug.vim'))
  finish
endif

call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'

call plug#end()
