let g:ale_completion_enabled = 1

" Check JSX files with eslint in Ale
augroup FiletypeGroup
  autocmd!
  au BufNewFile,BufRead *.jsx set filetype=javascript.jsx
augroup END

let g:ale_linter_aliases = {'jsx': ['css', 'javascript']}
let g:ale_linters = {
  \ 'python': ['flake8'],
  \ 'javascript': ['eslint'],
  \ 'jsx': [],
  \ 'scala': []
  \ }
let g:ale_fixers = { 'python': ['autopep8'] }

" Open quickfix list automatically
let g:ale_open_list = 1

" let g:ale_completion_enabled = 1

" Go to the next error
nmap <silent> <leader>a <Plug>(ale_next_wrap)

" Disabling highlighting
let g:ale_set_highlights = 0

" Only run linting when saving the file
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 0

" Triggering ALE completion manually with <C-x><C-o>
set omnifunc=ale#completion#OmniFunc

" Use <Tab> to circle through completion suggestions
inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" : "\<TAB>"

" ALE LSP mappings. Only work with tsserver
" " Remap keys for gotos
" nmap <silent> gd <Plug>(ale_go_to_definition)
" nmap <silent> gy <Plug>(ale-go-to-type-definition)
" nmap <silent> gr <Plug>(ale_find_references)

" " Print brief information about the symbol under the cursor, taken from any
" nnoremap <silent> K <Plug>(ale_hover)

" " Remap for rename current word
" nmap <leader>rn :ALERename
