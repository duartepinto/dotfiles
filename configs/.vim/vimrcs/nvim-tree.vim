" vimrc

nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <C-f> :NvimTreeFindFile<CR>

" More available functions:
" NvimTreeOpen
" NvimTreeClose
" NvimTreeFocus
" NvimTreeFindFileToggle
" NvimTreeResize
" NvimTreeCollapse
" NvimTreeCollapseKeepBuffers

set termguicolors " this variable must be enabled for colors to be applied properly

" a list of groups can be found at `:help nvim_tree_highlight`
highlight NvimTreeFolderIcon guibg=blue


lua << EOF
  require'nvim-tree'.setup {
    git = {
      ignore = false
    },

    respect_buf_cwd = true, -- 0 by default, will change cwd of nvim-tree to that of new buffer's when opening nvim-tree.

    create_in_closed_folder = true, -- 0 by default, When creating files, sets the path of a file when cursor is on a closed folder to the parent folder when 0, and inside the folder when 1.

    renderer = {
      highlight_opened_files = "icon", -- "none" by default, will enable folder and file icon highlight for opened files/directories.

      group_empty = true, -- 0 by default, compact folders that only contain a single folder into one node in the file tree

      add_trailing = true, -- 0 by default, append a trailing slash to folder names

      root_folder_modifier = ':~', -- This is the default. See :help filename-modifiers for more options

      highlight_git = true, -- 0 by default, will enable file highlight for git attributes (can be used without the icons).

      special_files = {}, -- List of filenames that gets highlighted with NvimTreeSpecialFile

      icons = {
        padding = ' ', -- one space by default, used for rendering the space between the icon and the filename. Use with caution, it could break rendering if you set an empty string depending on your font.

        symlink_arrow = ' >> ', -- defaults to ' ? '. used as a separator between symlinks' source and target.

        show = {
          git = true,
          folder = false,
          file = false,
          folder_arrow = false
        },

        -- If 0, do not show the icons for one of 'git' 'folder' and 'files'
        -- 1 by default, notice that if 'files' is 1, it will only display
        -- if nvim-web-devicons is installed and on your runtimepath.
        -- if folder is 1, you can also tell folder_arrows 1 to show small arrows next to the folder icons.
        -- but this will not work when you set renderer.indent_markers.enable (because of UI conflict)

        -- default will show icon by default if no icon is provided
        -- default shows no icon by default
        glyphs = {
          default = "?",
          symlink = "?",
          git = {
            unstaged = "?",
            staged = "?",
            unmerged = "?",
            renamed = "?",
            untracked = "?",
            deleted = "?",
            ignored = "?"
          },
          folder = {
            arrow_open =  "?",
            arrow_closed = "?",
            default = "?",
            open = "?",
            empty = "?",
            empty_open = "?",
            symlink = "?",
            symlink_open = "?",
          }
        }
      }
    }
  }
EOF
