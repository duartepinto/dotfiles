set nocompatible              " be iMproved, required
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Plugins

Plugin 'godlygeek/tabular'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-surround'
Plugin 'bling/vim-airline' " Status bar at the bottom of vim
Plugin 'scrooloose/nerdcommenter'
Plugin 'valloric/youcompleteme', { 'do': './install.py --tern-completer' }
" Plugin 'easymotion/vim-easymotion' " Removed it because I should learn what it does before having it installed
"Plugin 'kaicataldo/material.vim' " Had to stop using this because of jsx syntax highlighting
Plugin 'altercation/vim-colors-solarized'

" Plugins for Latex
Plugin 'lervag/vimtex'

" Plugins for Markdown
Plugin 'plasticboy/vim-markdown'
Plugin 'suan/vim-instant-markdown'

" Plugins for Javascript
Plugin 'pangloss/vim-javascript'
"Plugin 'moll/vim-node'

" Plugins for React
Plugin 'maxmellon/vim-jsx-pretty'
Plugin 'mattn/emmet-vim'
Plugin 'skywind3000/asyncrun.vim' " Run commands asynchronously. To use with Prettier formater
"Plugin 'w0rp/ale'

" Plugins for Scala
Plugin 'derekwyatt/vim-scala'
"
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

set runtimepath+=~/.vim_runtime

source ~/.vim_runtime/vimrcs/basic.vim
source ~/.vim_runtime/vimrcs/filetypes.vim
source ~/.vim_runtime/vimrcs/plugins_config.vim
source ~/.vim_runtime/vimrcs/extended.vim

try
source ~/.vim_runtime/my_configs.vim
catch
endtry

" Colorscheme
syntax enable
set background=dark
"colorscheme material 
let g:solarized_termcolors=256
let g:solarized_termtrans=1
colorscheme solarized 

" Line numbers
set number relativenumber

augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

" Enable Github Flavored Markdown Preview
let vim_markdown_preview_github=1
let vim_markdown_preview_browser='Google Chrome'

" ==== NERDTREE
let NERDTreeIgnore = ['__pycache__', '\.pyc$', '\.o$', '\.so$', '\.a$', '\.swp', '*\.swp', '\.swo', '\.swn', '\.swh', '\.swm', '\.swl', '\.swk', '\.sw*$', '[a-zA-Z]*egg[a-zA-Z]*', '.DS_Store']

let NERDTreeShowHidden=1
let g:NERDTreeWinPos="left"
let g:NERDTreeDirArrows=0
map <C-t> :NERDTreeToggle<CR>

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" Don't use syntastic with these file extensions
let g:syntastic_mode_map = { 'passive_filetypes': ['tex', 'scala'] }

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

"let g:syntastic_python_checkers=['pyflakes', 'python3']
let g:syntastic_python_checkers=[]
let g:syntastic_javascript_checkers = ['eslint']

filetype plugin on

let maplocalleader = "\\"

" Automatically truncate the length of a line in Latex
autocmd FileType tex    set textwidth=82

" Make vimtex automatically open the evince instead of the default system viewer.

"let g:vimtex_view_general_viewer = 'evince'

if !exists('g:ycm_semantic_triggers')
    let g:ycm_semantic_triggers = {}
endif
let g:ycm_semantic_triggers.tex = g:vimtex#re#youcompleteme

" Option for Eclim to work
let g:EclimCompletionMethod = 'omnifunc'

" Enable mouse in all modes. I added this to allow mouse scroll with tmux
set mouse=a

" Make vim-jsx have syntax highlighting and identation only for .jsx files
"let g:jsx_ext_required = 1

" Unfold all by default
set foldlevel=99

let g:vim_jsx_pretty_colorful_config = 1 " default 0

autocmd BufWritePost *.js AsyncRun -post=checktime ./node_modules/.bin/eslint --fix %


" Make vim automatically refresh any files that haven't been edited by vim
set autoread
au FocusGained,BufEnter * :silent! !

" This will insert four spaces instead of a tab character.
" Spaces are a bit more “stable”, meaning that text indented with spaces will show up the
" same in the browser and any other application.
:set tabstop=2
:set shiftwidth=2
:set expandtab
