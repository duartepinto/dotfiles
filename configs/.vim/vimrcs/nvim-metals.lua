-------------------------------------------------------------------------------
-- These are example settings to use with nvim-metals and the nvim built-in
-- LSP. Be sure to thoroughly read the `:help nvim-metals` docs to get an
-- idea of what everything does. Again, these are meant to serve as an example,
-- if you just copy pasta them, then should work,  but hopefully after time
-- goes on you'll cater them to your own liking especially since some of the stuff
-- in here is just an example, not what you probably want your setup to be.
--
-- Unfamiliar with Lua and Neovim?
--  - Check out https://github.com/nanotee/nvim-lua-guide
--
-- The below configuration also makes use of the following plugins besides
-- nvim-metals, and therefore is a bit opinionated:
--
-- - https://github.com/hrsh7th/nvim-cmp
--   - hrsh7th/cmp-nvim-lsp for lsp completion sources
--   - hrsh7th/cmp-vsnip for snippet sources
--   - hrsh7th/vim-vsnip for snippet sources
--
-- - https://github.com/wbthomason/packer.nvim for package management
-- - https://github.com/mfussenegger/nvim-dap (for debugging)
-------------------------------------------------------------------------------
local api = vim.api
local cmd = vim.cmd
local map = vim.keymap.set

----------------------------------
-- OPTIONS -----------------------
----------------------------------
-- global
vim.opt_global.completeopt = { "menuone", "noinsert", "noselect" }

-- LSP mappings
map("n", "K", vim.lsp.buf.hover)
map("n", "gds", vim.lsp.buf.document_symbol)
map("n", "gws", vim.lsp.buf.workspace_symbol)
map("n", "<leader>cl", vim.lsp.codelens.run)
map("n", "<leader>sh", vim.lsp.buf.signature_help)
map("n", "<leader>rn", vim.lsp.buf.rename)
map("n", "<leader>F", vim.lsp.buf.format)
map("n", "<leader>A", vim.lsp.buf.code_action)
map("n", "<leader>aa", vim.diagnostic.setqflist) -- all workspace diagnostics
map("n", "Ks", function()
  local util = require("metals.util")
  local lsp = require("vim.lsp")
  opts = { wrap = false }

  local buf = api.nvim_get_current_buf()
  local line,_ = unpack(api.nvim_win_get_cursor(0))

  local hints = vim.lsp.inlay_hint.get({ bufnr = buf })

  local hintsFiltered = vim.tbl_filter(function(item)
    return item.inlay_hint.position.line == line -1
  end, hints)

  if #hintsFiltered == 0 then
    return
  elseif #hintsFiltered > 1 then
    log.error_and_show("Received two inlay hints on a single line. This should never happen with worksheets. Please create a nvim-metals issue.")
    return
  elseif #hintsFiltered == 1 then
    local hint = hintsFiltered[1]

    local client = vim.lsp.get_client_by_id(hint.client_id)
    local resp = client.request_sync('inlayHint/resolve', hint.inlay_hint, 100, 0)
    local resolved_hint = assert(resp and resp.result, resp.err)

    local hover_message = {}
    hover_message[1] = resolved_hint.tooltip

    -- This also shouldn't happen but to avoid an empty window we do a sanity check
    if hover_message[1] == nil then
      return
    end

    local floating_preview_opts = util.check_exists_and_merge({ pad_left = 1, pad_right = 1 }, opts)
    lsp.util.open_floating_preview(hover_message, "markdown", floating_preview_opts)
  end
end)
map("n", "<leader>ae", function() -- all workspace errors
  vim.diagnostic.setqflist({severity = "E"})
end)
map("n", "<leader>aw", function() -- all workspace warnings
  vim.diagnostic.setqflist({severity = "W"})
end)
map("n", "[g", function()
  vim.diagnostic.goto_prev { wrap = false }
end)
map("n", "]g", function()
  vim.diagnostic.goto_next { wrap = false }
end)

-- Defaults from nvim-metals suggested config
-- map("n", "gd", vim.lsp.buf.definition)
-- map("n", "gi", vim.lsp.buf.implementation)
-- map("n", "gr", vim.lsp.buf.references)
-- map("n", "<leader>d", vim.diagnostic.setloclist)
-- Overriden:
map("n", "gd", function()
  require("telescope.builtin").lsp_definitions()
end)
map("n", "gi", function()
  require("telescope.builtin").lsp_implementations()
end)
map("n", "gr", function()
  require("telescope.builtin").lsp_references()
end)
map("n", "<leader>d", function() -- buffer diagnostics only
  require("telescope.builtin").diagnostics()
end)

-- completion related settings
-- This is similiar to what I use
local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp" },
    { name = "vsnip" },
  },
  snippet = {
    expand = function(args)
      -- Comes from vsnip
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    -- None of this made sense to me when first looking into this since there
    -- is no vim docs, but you can't have select = true here _unless_ you are
    -- also using the snippet stuff. So keep in mind that if you remove
    -- snippets you need to remove this select
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    -- I use tabs... some say you should stick to ins-completion but this is just here as an example
    ["<Tab>"] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    ["<S-Tab>"] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end,
    ["<C-j>"] = function(fallback)
      cmp.mapping.abort()
      local copilot_keys = vim.fn["copilot#Accept"]()
      if copilot_keys ~= "" then
        vim.api.nvim_feedkeys(copilot_keys, "i", true)
      else
        fallback()
      end
    end,
  }),
})

----------------------------------
-- LSP Setup ---------------------
----------------------------------
local metals_config = require("metals").bare_config()

-- Example of settings
metals_config.settings = {
  showImplicitArguments = false,
  excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
  serverProperties = {
    -- "-Dmetals.enable-best-effort=true",
  },
}

-- *READ THIS*
-- I *highly* recommend setting statusBarProvider to true, however if you do,
-- you *have* to have a setting to display this in your statusline or else
-- you'll not see any messages from metals. There is more info in the help
-- docs about this
metals_config.init_options.statusBarProvider = "off"

-- Example if you are using cmp how to make sure the correct capabilities for snippets are set
metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Autocmd that will actually be in charging of starting the whole thing
local nvim_metals_group = api.nvim_create_augroup("nvim-metals", { clear = true })
api.nvim_create_autocmd("FileType", {
  -- NOTE: You may or may not want java included here. You will need it if you
  -- want basic Java support but it may also conflict if you are using
  -- something like nvim-jdtls which also works on a java filetype autocmd.
  pattern = { "scala", "sbt", "java", "sc" },
  callback = function()
    require("metals").initialize_or_attach(metals_config)
  end,
  group = nvim_metals_group,
})
