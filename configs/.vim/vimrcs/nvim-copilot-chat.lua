local map = vim.keymap.set

map("n", "<leader>zc", require("CopilotChat").open) -- open chat
map("n", "<leader>zr", "<cmd>CopilotChatReview<cr>" ) -- Review code
map("n", "<leader>zt", "<cmd>CopilotChatTests<cr>" ) -- Generate tests
map("n", "<leader>zm", "<cmd>CopilotChatCommit<cr>" ) -- Create a commit message
map("v", "<leader>zm", "<cmd>CopilotChatCommit<cr>" ) -- Create a commit message for the selection

require("CopilotChat").setup {
  model = 'claude-3.7-sonnet', -- default model
  --
  -- default mappings
  -- see config/mappings.lua for implementation
  mappings = {
    complete = {
      insert = '<Tab>',
    },
    close = {
      normal = 'q',
      insert = '<C-c>',
    },
    reset = {
      normal = 'gl',
      insert = '<C-l>',
    },
    submit_prompt = {
      normal = '<CR>',
      insert = '<C-s>',
    },
    toggle_sticky = {
      detail = 'Makes line under cursor sticky or deletes sticky line.',
      normal = 'gr',
    },
    accept_diff = {
      normal = '<C-y>',
      insert = '<C-y>',
    },
    jump_to_diff = {
      normal = 'gj',
    },
    quickfix_answers = {
      normal = 'gqa',
    },
    quickfix_diffs = {
      normal = 'gqd',
    },
    yank_diff = {
      normal = 'gy',
      register = '"', -- Default register to use for yanking
    },
    show_diff = {
      normal = 'gd',
      full_diff = false, -- Show full diff instead of unified diff when showing diff window
    },
    show_info = {
      normal = 'gi',
    },
    show_context = {
      normal = 'gc',
    },
    show_help = {
      normal = 'gh',
    },
  }
}
