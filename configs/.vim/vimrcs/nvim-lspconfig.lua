local lspconfig = require('lspconfig')

lspconfig.tsserver.setup {
  on_attach = on_attach,
  filetypes = {"typescript", "typescriptreact", "typescript.tsx", "javascript", "jsx"},
  cmd = { "typescript-language-server", "--stdio" },
}
