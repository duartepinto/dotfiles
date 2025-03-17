local map = vim.keymap.set

-- Function to handle git diff with CopilotChat integration
local function git_diff_with_copilot(prompt)
  -- Get input from user with abort on escape
  local input = vim.fn.input({
    prompt = "Git diff arguments (leave empty for default): ",
    cancelreturn = "__CANCEL__"  -- Special value to detect cancellation
  })

  -- Check if user canceled input
  if input == "__CANCEL__" then
    vim.notify("Git diff operation cancelled", vim.log.levels.INFO)
    return
  end

  local cmd = "git diff " .. (input ~= "" and input or "")

  -- Run git diff
  local diff_output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Git diff failed: " .. diff_output, vim.log.levels.ERROR)
    return
  end

  -- Create buffer name based on the git command
  local buffer_name = "[Git] " .. cmd

  -- Create a new buffer for the diff output
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diff_output, "\n"))
  vim.api.nvim_buf_set_option(buf, "filetype", "diff")

  -- Set the buffer name
  vim.api.nvim_buf_set_name(buf, buffer_name)

  -- Use a split instead of a floating window for better integration
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Wait for buffer to fully load, then run CopilotChat
  vim.defer_fn(function()
    -- Make sure we're still in the right buffer
    if vim.api.nvim_get_current_buf() == buf then
      -- Apply the specified prompt
      vim.cmd("CopilotChat " .. buf .. " " .. prompt)
    end
  end, 300)
end

map("n", "<leader>zc", require("CopilotChat").open) -- open chat
map("n", "<leader>zr", "<cmd>CopilotChatReview<cr>" ) -- Review code
map("n", "<leader>zt", "<cmd>CopilotChatTests<cr>" ) -- Generate tests
map("n", "<leader>zm", "<cmd>CopilotChatCommit<cr>" ) -- Create a commit message
map("v", "<leader>zm", "<cmd>CopilotChatCommit<cr>" ) -- Create a commit message for the selection
map("n", "<leader>zdr", function()
  git_diff_with_copilot("Review this git diff and suggest improvements")
end, { noremap = true, silent = true, desc = "CopilotChat: Review git diff" })
map("n", "<leader>zd", function()
  git_diff_with_copilot("Explain this git diff")
end, { noremap = true, silent = true, desc = "CopilotChat: Explain git diff" })

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
