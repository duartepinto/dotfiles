vim.lsp.config('ts_ls', {
  on_attach = on_attach,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx", "javascript", "jsx"},
  cmd = { "typescript-language-server", "--stdio" },
})

vim.lsp.enable('pyright')
