set nocompatible              " be iMproved, required
call plug#begin('~/.vim/plugged')
" Plugins

Plug 'godlygeek/tabular'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-surround'
Plug 'bling/vim-airline' " Status bar at the bottom of vim
Plug 'scrooloose/nerdcommenter'
Plug 'valloric/youcompleteme', { 'do': './install.py --tern-completer' }
" Plug 'easymotion/vim-easymotion' " Removed it because I should learn what it does before having it installed
Plug 'altercation/vim-colors-solarized'
Plug 'natebosch/vim-lsc', {'for': ['scala']} " Language Server Client
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'diepm/vim-rest-console'

" Fuzzy search for vim
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

" Plugins for Python
Plug 'vim-python/python-syntax'

" Plugins for Latex
Plug 'lervag/vimtex'

" Plugins for Markdown
Plug 'plasticboy/vim-markdown'
Plug 'suan/vim-instant-markdown'

" Plugins for Javascript
Plug 'pangloss/vim-javascript'
Plug 'elzr/vim-json'
"Plug 'moll/vim-node'

" Plugins for React
Plug 'maxmellon/vim-jsx-pretty'
Plug 'mattn/emmet-vim'
Plug 'skywind3000/asyncrun.vim' " Run commands asynchronously. To use with Prettier formater

" Plugins for Scala
Plug 'derekwyatt/vim-scala'
Plug 'GEverding/vim-hocon'

call plug#end()

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
colorscheme solarized 

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

let NERDTreeShowHidden=1
let g:NERDTreeWinPos="left"
let g:NERDTreeDirArrows=0
let NERDTreeMinimalUI = 1
map <C-n> :NERDTreeToggle<CR>
map <C-y> :NERDTreeFind<CR>

" Automatically close a tab if the only remaining window is NerdTree 
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" Don't use syntastic with these file extensions
let g:syntastic_mode_map = { 
  \ "mode": "passive",  
  \ 'passive_filetypes': ['tex', 'scala', 'python']
  \ }

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_python_checkers=['pep8']
let g:syntastic_javascript_checkers = ['eslint']

filetype plugin on

"let maplocalleader = "\\"
let maplocalleader="\<space>"

" Automatically truncate the length of a line in Latex
autocmd FileType tex    set textwidth=82

" Make vimtex automatically open evince instead of the default system viewer.
"let g:vimtex_view_general_viewer = 'evince'

" %%%%%%%%%% MAC OS ONLY %%%%%%%%%%
" Make vimtex automatically open skim instead of the default system viewer. Better for Mac OS.
let g:vimtex_view_general_viewer 
      \ = '/Applications/Skim.app/Contents/SharedSupport/displayline'
let g:vimtex_view_general_options = '-r @line @pdf @tex'
let g:vimtex_compiler_callback_hooks = ['UpdateSkim']
function! UpdateSkim(status)
  if !a:status | return | endif

  let l:out = b:vimtex.out()
  let l:tex = expand('%:p')
  let l:cmd = [g:vimtex_view_general_viewer, '-r']
  if !empty(system('pgrep Skim'))
    call extend(l:cmd, ['-g'])
  endif
  if has('nvim')
    call jobstart(l:cmd + [line('.'), l:out, l:tex])
  elseif has('job')
    call job_start(l:cmd + [line('.'), l:out, l:tex])
  else
    call system(join(l:cmd + [line('.'),
          \ shellescape(l:out), shellescape(l:tex)], ' '))
  endif
endfunction

" %%%%%%%%%% END OF MAC OS ONLY %%%%%%%%%%

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

" Run Prettier and reload buffer after complete. For .js files
autocmd BufWritePost *.js AsyncRun -post=checktime ./node_modules/.bin/eslint --fix %

" Make vim automatically refresh any files that haven't been edited by vim
set autoread
au FocusGained,BufEnter * :silent! !

" This will insert 2 spaces instead of a tab character.
" Spaces are a bit more “stable”, meaning that text indented with spaces will show up the
" same in the browser and any other application.
:set tabstop=2
:set shiftwidth=2
:set expandtab

" For Python files only
" This will insert 4 spaces instead of a tab character.
" Spaces are a bit more “stable”, meaning that text indented with spaces will show up the
" same in the browser and any other application.
aug python
  " ftype/python.vim overwrites this
  au FileType python setlocal ts=4 sts=4 sw=4 expandtab
aug end

" Configuration for vim-scala. To use with metals
au BufRead,BufNewFile *.sbt set filetype=scala

" Configuration for vim-lsc. To use with metals
let g:lsc_enable_autocomplete = v:false
let g:lsc_server_commands = {
  \  'scala': {
  \    'command': 'metals-vim',
  \    'log_level': 'Log'
  \  }
  \}

let g:lsc_auto_map = {
  \ 'GoToDefinition': 'gd',
  \ 'GoToDefinitionSplit': ['<C-W>]', '<C-W><C-]>'],
  \ 'FindReferences': 'gr',
  \ 'FindCodeActions': 'ga',
  \ 'Rename': 'gR',
  \}

" Enable gitgutter by default (Plugin airblade/vim-gitgutter). 
let g:gitgutter_enabled = 1

" Update GitGutter on save
autocmd BufWritePost * GitGutter

" Scala Import sort (vim-scala)
let g:scala_sort_across_groups = 1
let g:scala_first_party_namespaces = '\(eu.shiftforward.*\|com.velocidi.*\)'

" Custom comment delimiters for NERDCommenter
let g:NERDCustomDelimiters = {
  \ 'hocon': { 'left': '#', 'right': ''  },
  \ }
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Disable Ale. Comes installed with amix/vimrc 
" let g:ale_enabled = 0

" Check JSX files with eslint in Ale
augroup FiletypeGroup
  autocmd!
  au BufNewFile,BufRead *.jsx set filetype=javascript.jsx
augroup END

let g:ale_linter_aliases = {'jsx': ['css', 'javascript']}
let g:ale_linters = {
  \ 'python': ['flake8'],
  \ 'jsx': ['eslint'],
  \ 'scala': []
  \ }
let g:ale_fixers = { 'python': ['autopep8'] }

" Open quickfix list automatically
let g:ale_open_list = 1

let g:ale_completion_enabled = 1

nmap <leader><tab> :Files<Enter>
