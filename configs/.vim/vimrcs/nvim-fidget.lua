require("fidget").setup({
  notification = {
    window = {
      winblend = 0,
      relative = "editor",
      x_padding = 1,
    },
  },
})

-- Adjust fidget x_padding based on Avante window in the current tab
local function get_avante_width_in_current_tab()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local avante_width = 0

  -- Only check windows in the current tab
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    if ft == "Avante" or ft == "AvanteInput" then
      avante_width = vim.api.nvim_win_get_width(win)
      break
    end
  end

  return avante_width
end

local function update_fidget_x_padding()
  local avante_width = get_avante_width_in_current_tab()
  require("fidget").setup({
    notification = {
      window = {
        winblend = 0,
        relative = "editor",
        x_padding = avante_width > 0 and (avante_width + 1) or 1,
      },
    },
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "Avante", "AvanteInput" },
  callback = update_fidget_x_padding,
})

vim.api.nvim_create_autocmd("WinClosed", {
  callback = function()
    vim.schedule(update_fidget_x_padding)
  end,
})

-- Update fidget padding when switching tabs
vim.api.nvim_create_autocmd("TabEnter", {
  callback = update_fidget_x_padding,
})

