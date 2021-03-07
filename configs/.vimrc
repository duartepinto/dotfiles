set nocompatible              " be iMproved, required

source ~/.vim/vimrcs/basic.vim
source ~/.vim/vimrcs/ale.vim

call plug#begin('~/.vim/plugged')
" Plugins

Plug 'godlygeek/tabular'
Plug 'tpope/vim-surround'
Plug 'itchyny/lightline.vim' " Statusbar/Tabline plugin
Plug 'maximbaz/lightline-ale'
Plug 'altercation/vim-colors-solarized'
Plug 'lifepillar/vim-solarized8'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'diepm/vim-rest-console'
Plug 'tmux-plugins/vim-tmux-focus-events' " Autoread with tmux
Plug 'w0rp/ale'
Plug 'mileszs/ack.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'airblade/vim-gitgutter'
Plug 'maxbrunsfeld/vim-yankstack'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'for': ['scala', 'javascript.jsx']}

" Fuzzy search for vim
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

" Plugins for Python
Plug 'vim-python/python-syntax'

" Plugins for Latex
Plug 'valloric/youcompleteme', { 'do': './install.py --tern-completer', 'for': ['tex'] }
Plug 'lervag/vimtex'

" Plugins for Markdown
Plug 'plasticboy/vim-markdown'
Plug 'suan/vim-instant-markdown', { 'do': 'npm install -g instant-markdown-d', 'for': 'markdown' }

" Plugins for Javascript
Plug 'pangloss/vim-javascript'
Plug 'elzr/vim-json'
Plug 'mustache/vim-mustache-handlebars'

" Plugins for React
Plug 'maxmellon/vim-jsx-pretty'
Plug 'mattn/emmet-vim'
Plug 'skywind3000/asyncrun.vim' " Run commands asynchronously. To use with Prettier formater

" Plugins for Scala
Plug 'derekwyatt/vim-scala'
Plug 'GEverding/vim-hocon'

" Plugins for Swift
Plug 'bumaociyuan/vim-swift'

" Plugins for Kotlin
Plug 'udalov/kotlin-vim'

" Plugins for ruby
Plug 'vim-ruby/vim-ruby'

call plug#end()

" Colorscheme
set background=dark
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
" let g:solarized_term_italics=1
set termguicolors

colorscheme solarized8

" Line numbers
set number relativenumber

augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

" Enable Github Flavored Markdown Preview
" let vim_markdown_preview_github=1
" let vim_markdown_preview_browser='Google Chrome'

" ==== NERDTREE
let NERDTreeIgnore = ['__pycache__', '\.pyc$', '\.o$', '\.so$', '\.a$', '\.swp', '*\.swp', '\.swo', '\.swn', '\.swh', '\.swm', '\.swl', '\.swk', '\.sw*$', '[a-zA-Z]*egg[a-zA-Z]*', '.DS_Store']

let g:NERDTreeWinSize=35
let NERDTreeShowHidden=1
let g:NERDTreeWinPos="left"
let g:NERDTreeDirArrows=0
let NERDTreeMinimalUI = 1
map <C-n> :NERDTreeToggle<CR>
map <C-f> :NERDTreeFind<CR>

" Automatically close a tab if the only remaining window is NerdTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

set statusline+=%#warningmsg#
set statusline+=%*

filetype plugin on

"let maplocalleader = "\\"
let maplocalleader="\<space>"

" Enable mouse in all modes. I added this to allow mouse scroll with tmux
set mouse=a

" Make vim-jsx have syntax highlighting and identation only for .jsx files
"let g:jsx_ext_required = 1

" Unfold all by default
set foldlevel=99

let g:vim_jsx_pretty_colorful_config = 1 " default 0

" Make vim automatically refresh any files that haven't been edited by vim
set autoread
au FocusGained,BufEnter * :silent! !

" This will insert 2 spaces instead of a tab character.
" Spaces are a bit more “stable”, meaning that text indented with spaces will show up the
" same in the browser and any other application.
:set tabstop=2
:set shiftwidth=2
:set expandtab

" Enable gitgutter by default (Plugin airblade/vim-gitgutter).
let g:gitgutter_enabled = 1

" Update GitGutter on save
autocmd BufWritePost * GitGutter

highlight! link SignColumn LineNr

" Custom comment delimiters for NERDCommenter
let g:NERDCustomDelimiters = {
  \ 'hocon': { 'left': '#', 'right': ''  },
  \ }
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Press ',<TAB>' to execute fzf Files command
nmap <leader><tab> :Files<Enter>

" Using Ripgrep with Vim in CtrlP and Ack.vim
if executable('rg')
  let g:ctrlp_user_command = 'rg --files %s'
  let g:ctrlp_use_caching = 0
  let g:ctrlp_working_path_mode = 'ra'
  let g:ctrlp_switch_buffer = 'et'
  let g:ackprg = 'rg --vimgrep --no-heading'
endif

" Empty value to disable 'fzf.vim' preview window altogether
let g:fzf_preview_window = ''

" Make fzf window appear in the same place as it used to in previous versions
let g:fzf_layout = { 'window': { 'width': 1, 'height': 0.4, 'yoffset': 1, 'border': 'horizontal'  }  }

" Open Fzf with text search  (overrides Ack shortcut)
map <leader>g :Rg<Enter>

" Fix bug where mouse click doesn't work past the 220th column (https://stackoverflow.com/questions/7000960/in-vim-why-doesnt-my-mouse-work-past-the-220th-column)
" FIXME: Remove when possible. The issue mentions that it is fixed in version 7.3.632, but that doesn't seem to be the case
set ttymouse=sgr

" Disable vim-json from concealing double-quotes
let g:vim_json_syntax_conceal = 0

" Increase maxmempattern (default 1000)
" https://github.com/vim/vim/issues/2049#issuecomment-494923065
set mmp=3000

" Fast editing and reloading of vimrc configs (copy of ~/.vim_runtime/vimrcs/extended.vim)
map <leader>e :e! ~/.vimrc<cr>

" Yankstack
let g:yankstack_yank_keys = ['y', 'd']
nmap <C-p> <Plug>yankstack_substitute_older_paste
nmap <C-P> <Plug>yankstack_substitute_newer_paste

" lightline configs
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ ['mode', 'paste'],
      \             ['fugitive', 'readonly', 'filename', 'modified'] ],
      \   'right': [ [ 'lineinfo' ], ['percent'] ]
      \ },
      \ 'component': {
      \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒":""}',
      \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
      \   'fugitive': '%{exists("*FugitiveHead")?FugitiveHead():""}'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(&filetype!="help"&& &readonly)',
      \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(exists("*FugitiveHead") && ""!=FugitiveHead())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': ' ', 'right': ' ' }
      \ }

" %%%%%%%%%% CTRLP %%%%%%%%%%
let g:ctrlp_working_path_mode = 0

" Quickly find and open a file in the current working directory
" let g:ctrlp_map = '<C-f>'
map <leader>j :CtrlP<cr>

" Quickly find and open a buffer
map <leader>b :CtrlPBuffer<cr>

" Quickly find and open a recently opened file
map <leader>f :CtrlPMRU<CR>

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = 'node_modules\|^\.DS_Store\|^\.git\|^\.coffee'

" For lightline + CtrlP integration
" https://github.com/itchyny/lightline.vim/issues/16#issuecomment-23462561
function! MyFilename()
  if expand('%:t') == 'ControlP'
    return g:lightline.ctrlp_prev . ' ' . g:lightline.subseparator.left . ' ' .
          \ g:lightline.ctrlp_item . ' ' . g:lightline.subseparator.left . ' ' .
          \ g:lightline.ctrlp_next
  endif
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
        \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
        \  &ft == 'unite' ? unite#get_status_string() :
        \  &ft == 'vimshell' ? vimshell#get_status_string() :
        \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
        \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! CtrlPMark()
  return expand('%:t') =~ 'ControlP' ? g:lightline.ctrlp_marked : ''
endfunction

let g:ctrlp_status_func = {
  \ 'main': 'CtrlPStatusFunc_1',
  \ 'prog': 'CtrlPStatusFunc_2',
  \ }
function! CtrlPStatusFunc_1(focus, byfname, regex, prev, item, next, marked)
  let g:lightline.ctrlp_prev = a:prev
  let g:lightline.ctrlp_item = a:item
  let g:lightline.ctrlp_next = a:next
  let g:lightline.ctrlp_marked = a:marked
  return lightline#statusline(0)
endfunction
function! CtrlPStatusFunc_2(str)
  return lightline#statusline(0)
endfunction

" %%%%%%%%%% END OF CTRLP %%%%%%%%%%

" When you press <leader>r you can search and replace the selected text.
" From `extended.vim` in  https://github.com/amix/vimrc
vnoremap <silent> <leader>r :call VisualSelection('replace', '')<CR>

" Set font according to system.
" From `extended.vim` in  https://github.com/amix/vimrc
if has("mac") || has("macunix")
    set gfn=IBM\ Plex\ Mono:h14,Hack:h14,Source\ Code\ Pro:h15,Menlo:h15
elseif has("win16") || has("win32")
    set gfn=IBM\ Plex\ Mono:h14,Source\ Code\ Pro:h12,Bitstream\ Vera\ Sans\ Mono:h11
elseif has("gui_gtk2")
    set gfn=IBM\ Plex\ Mono\ 14,:Hack\ 14,Source\ Code\ Pro\ 12,Bitstream\ Vera\ Sans\ Mono\ 11
elseif has("linux")
    set gfn=IBM\ Plex\ Mono\ 14,:Hack\ 14,Source\ Code\ Pro\ 12,Bitstream\ Vera\ Sans\ Mono\ 11
elseif has("unix")
    set gfn=Monospace\ 11
endif

" Turn persistent undo on means that you can undo even when you close a buffer/VIM.
" From `extended.vim` in  https://github.com/amix/vimrc
try
    set undodir=~/.vim_runtime/temp_dirs/undodir
    set undofile
catch
endtry

" Delete trailing whitespaces when saving the buffer
autocmd BufWritePre * :%s/\s\+$//e
