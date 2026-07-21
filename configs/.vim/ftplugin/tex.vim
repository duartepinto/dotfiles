" Maximum line length in LaTeX: drives auto-wrap while typing and the wrap
" width used by VimTeX's formatter (gq / <leader>F).
setlocal textwidth=80

" Make vimtex automatically open evince instead of the default system viewer.
"let g:vimtex_view_general_viewer = 'evince'

" %%%%%%%%%% MAC OS ONLY %%%%%%%%%%
" VimTeX's built-in Skim backend: auto-reloads Skim + forward-search on every
" successful compile. Replaces the deprecated g:vimtex_compiler_callback_hooks
" + custom UpdateSkim approach.
let g:vimtex_view_method = 'skim'
" %%%%%%%%%% END OF MAC OS ONLY %%%%%%%%%%

" Enable VimTeX's latexindent-based, LaTeX-aware formatting via `gq`.
"   gqq = current line, gqip = paragraph/entry, <leader>F = whole file
let g:vimtex_format_enabled = 1
" Format the whole file, restoring the cursor position afterwards.
nnoremap <buffer> <leader>F mzgggqG`z

if !exists('g:ycm_semantic_triggers')
    let g:ycm_semantic_triggers = {}
endif
let g:ycm_semantic_triggers.tex = g:vimtex#re#youcompleteme

let g:tex_flavor = "latex"
