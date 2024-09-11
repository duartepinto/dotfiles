set nocompatible              " be iMproved, required

call plug#begin('~/.vim/plugged')
" Plugins

Plug 'godlygeek/tabular'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-abolish' " better replace (like keeping case)
Plug 'itchyny/lightline.vim' " Statusbar/Tabline plugin
Plug 'maxmx03/solarized.nvim', {'branch': 'v3.0.0'}
Plug 'scrooloose/nerdcommenter'
Plug 'diepm/vim-rest-console'
Plug 'tmux-plugins/vim-tmux-focus-events' " Autoread with tmux
Plug 'airblade/vim-gitgutter'
Plug 'maxbrunsfeld/vim-yankstack'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'for': ['javascript.jsx', 'typescript']}
Plug 'lambdalisue/suda.vim' " sudo save for nvim
Plug 'chunkhang/vim-mbsync'
Plug 'elzr/vim-json'
Plug 'neovim/nvim-lsp'
Plug 'github/copilot.vim'

"nvim specfic
Plug 'lukas-reineke/indent-blankline.nvim' " Identation guides
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} " nvim syntax highlight
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'j-hui/fidget.nvim'

" Fuzzy search for vim
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

" Plugins for Latex
Plug 'valloric/youcompleteme', { 'do': './install.py --tern-completer', 'for': ['tex'] }
Plug 'lervag/vimtex'

" Plugins for Markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }

" Plugins for Javascript
Plug 'mustache/vim-mustache-handlebars' " working with mustache and handlebars template languages.

" Plugins for React
Plug 'groenewege/vim-less' " Syntax highlighting, indenting and autocompletion for the dynamic stylesheet language LESS.

" Plugins for Scala
Plug 'derekwyatt/vim-scala'
Plug 'hrsh7th/nvim-cmp' " Necessary for nvim-metals
Plug 'hrsh7th/cmp-nvim-lsp' " Necessary for nvim-metals
Plug 'hrsh7th/cmp-vsnip' " Necessary for nvim-metals
Plug 'hrsh7th/vim-vsnip' " Necessary for nvim-metals
Plug 'scalameta/nvim-metals'

" Plugins for ruby
Plug 'vim-ruby/vim-ruby'

call plug#end()

source ~/.vim/vimrcs/basic.vim
if has('nvim')
  source ~/.vim/vimrcs/nvim-tree.vim
  source ~/.vim/vimrcs/nvim-telescope.vim
  source ~/.vim/vimrcs/nvim-lspconfig.lua
  source ~/.vim/vimrcs/nvim-metals.lua
  source ~/.vim/vimrcs/nvim-treesitter.lua
  source ~/.vim/vimrcs/nvim-fidget.lua

lua << EOF
vim.g.copilot_assume_mapped = true
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""

vim.lsp.inlay_hint.enable()
EOF

endif

" Colorscheme
set background=dark
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
let g:solarized_term_italics=1
set termguicolors

colorscheme solarized

" Line numbers
set number relativenumber

" Automatic switch between relative numbers or not
" Copy of 'jeffkreeftmeijer/vim-numbertoggle'
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

set statusline+=%#warningmsg#
set statusline+=%*

"let maplocalleader = "\\"
let maplocalleader="\<space>"

" Enable mouse in all modes. I added this to allow mouse scroll with tmux
set mouse=a

" Unfold all by default
set foldlevel=99

let g:vim_jsx_pretty_colorful_config = 1 " default 0

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
      \   'fugitive': '%{exists("*FugitiveHead")?FugitiveHead():""}',
      \   'metalsstatus': '%{MetalsStatus()}'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(&filetype!="help"&& &readonly)',
      \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(exists("*FugitiveHead") && ""!=FugitiveHead())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': ' ', 'right': ' ' }
      \ }


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
    set undodir=~/.vim/temp_dirs/undodir
    set undofile
catch
endtry

" Delete trailing whitespaces when saving the buffer
autocmd BufWritePre * :%s/\s\+$//e

" Vimrest default response content-type to JSON
" To allow for syntax hightlight in response
let b:vrc_response_default_content_type = 'application/json'

" Make .h files be interpreted as Objective-C
au BufRead,BufNewFile *.h set filetype=objc

" markdown-preview.nvim configs
let g:mkdp_preview_options = {
  \ 'disable_sync_scroll': 1,
  \ }
" set to 1, nvim will open the Markdown preview window after entering the Markdown buffer
" default: 0
let g:mkdp_auto_start = 1
" combine Markdown preview window
" default: 0
" if enable it will reuse previous opened preview window when you preview markdown file.
" ensure to set let g:mkdp_auto_close = 0 if you have enable this option
let g:mkdp_combine_preview = 1
" set to 1, the Markdown preview server is available to others in your network.
" By default, the server listens on localhost (127.0.0.1)
" default: 0
let g:mkdp_open_to_the_world = 1
" use a custom port to start Markdown preview server or empty for random
let g:mkdp_port = '8090'
" auto refetch combine preview contents when change markdown buffer
" only when g:mkdp_combine_preview is 1
let g:mkdp_combine_preview_auto_refresh = 1

" Change cursor in Insert mode
" Might disable it because it is a bit slow when going back to Normal mode and because it messes with TMUX.
" https://stackoverflow.com/questions/6488683/how-to-change-the-cursor-between-normal-and-insert-modes-in-vim
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Highlight cursor line when in Insert mode
autocmd InsertEnter,InsertLeave * set cul!

" Help Vim recognize *.sbt and *.sc as Scala files
au BufRead,BufNewFile *.sbt,*.sc set filetype=scala

" Use Scaladoc identation standard (gutter asterisks aligned in column three).
" http://docs.scala-lang.org/style/scaladoc.html
let g:scala_scaladoc_indent = 1

if has('nvim')
  " :W sudo saves the file
  " uses suda.vim since nvim does not have this natively
  command! W execute 'SudaWrite'

  " Common accross nvim.lsp
  autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
  autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
  autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
endif

" Detect .conf files as hocon
au BufRead,BufNewFile *.conf set filetype=hocon

" Format JSON witg jq
command JsonFormatCurrentBuffer :%!jq .

command XmlFormatCurrentBuffer :%!xmllint --format -
