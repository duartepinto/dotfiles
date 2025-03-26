local lspconfig = require('lspconfig')

lspconfig.ts_ls.setup {
  on_attach = on_attach,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx", "javascript", "jsx"},
  cmd = { "typescript-language-server", "--stdio" },
}

lspconfig.pyright.setup{}
