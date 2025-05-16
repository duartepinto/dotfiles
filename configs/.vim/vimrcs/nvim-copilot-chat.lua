local map = vim.keymap.set

vim.cmd([[
  function! GitDiffCompletion(ArgLead, CmdLine, CursorPos)
    let options = [
      \ '--cached', '--staged', '--name-only', '--name-status',
      \ '--stat', '--summary', '--patch', '-p',
      \ '--color', '--no-color', '--word-diff', '--unified=',
      \ '--output-indicator-new=', '--output-indicator-old=',
      \ '--abbrev', '--no-abbrev', '--binary',
      \ 'HEAD~1', 'HEAD~2', 'HEAD~3', 'main', 'master', 'origin/'
    \ ]

    " Check for ... or .. operators
    if a:ArgLead =~ '\.\.\.\|\.\..'
      " Extract what's after ... or .. for branch completion
      let parts = split(a:ArgLead, '\.\.\.\|\.\.')
      if len(parts) > 1
        let branch_prefix = parts[1]
        let local_branches = systemlist('git branch --format="%(refname:short)" 2>/dev/null')
        let remote_branches = systemlist('git branch -r --format="%(refname:short)" 2>/dev/null')

        " Filter branches based on the prefix after ... or ..
        call filter(local_branches, 'v:val =~ "^" . branch_prefix')
        call filter(remote_branches, 'v:val =~ "^origin/" . branch_prefix')
        call map(remote_branches, 'substitute(v:val, "^origin/", "", "")')

        " Create full completion items by preserving the first part and the operator
        let operator = a:ArgLead =~ '\.\.\.' ? '...' : '..'
        let first_part = parts[0]
        let completions = []
        for branch in local_branches + remote_branches
          call add(completions, first_part . operator . branch)
        endfor

        return completions
      endif
    endif

    " Check if the user is trying to complete a path
    if a:ArgLead =~ '^[^-]' || a:ArgLead == ''
      " Get file completions using glob
      let file_completions = glob(a:ArgLead . '*', 0, 1)

      " Add trailing slash to directories for better UX
      call map(file_completions, 'isdirectory(v:val) ? v:val . "/" : v:val')

      " Add git branches if the input doesn't look like a file path
      if a:ArgLead !~ '/' && a:ArgLead !~ '\\'
        " Get local branches
        let local_branches = systemlist('git branch --format="%(refname:short)" 2>/dev/null')
        call filter(local_branches, 'v:val =~ "^" . a:ArgLead')
        call extend(file_completions, local_branches)

        " Get remote branches with origin/ prefix
        let remote_branches = systemlist('git branch -r --format="%(refname:short)" 2>/dev/null')
        call filter(remote_branches, 'v:val =~ "^origin/" . a:ArgLead')
        call map(remote_branches, 'substitute(v:val, "^origin/", "", "")')
        call extend(file_completions, remote_branches)
      endif

      " Add git-tracked files if lead is empty
      if a:ArgLead == ''
        let git_files = systemlist('git ls-files 2>/dev/null')
        call extend(file_completions, git_files)
      endif

      " Filter, sort, and remove duplicates
      call filter(file_completions, 'v:val =~ "^" . a:ArgLead')
      let file_completions = uniq(sort(file_completions))
      return file_completions
    endif

    " Standard options completion
    return filter(copy(options), 'v:val =~ "^" . a:ArgLead')
  endfunction

]])

-- Function to handle git diff with CopilotChat integration
local function git_diff_with_copilot(prompt)
  -- Get input from user with abort on escape
  local input = vim.fn.input({
    prompt = "Git diff arguments (leave empty for default): ",
    cancelreturn = "__CANCEL__",  -- Special value to detect cancellation
    completion = "customlist,GitDiffCompletion"
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

  -- Extract filenames from the git diff
  local files = {}
  -- Look for lines starting with +++ b/ or --- a/ (indicating file paths)
  for line in diff_output:gmatch("[^\r\n]+") do
    local file_path = line:match("^%+%+%+ b/(.+)$") or line:match("^%-%-% a/(.+)$")
    if file_path and not vim.tbl_contains(files, file_path) then
      table.insert(files, file_path)
    end
  end

  -- Create buffer name based on the git command with timestamp to avoid naming conflicts
  local timestamp = os.time()
  local buffer_name = "[Git] " .. cmd .. " " .. timestamp

  -- Create a new buffer for the diff output
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diff_output, "\n"))
  vim.api.nvim_buf_set_option(buf, "filetype", "diff")

  -- Safely set the buffer name using pcall to catch any errors
  pcall(function()
    vim.api.nvim_buf_set_name(buf, buffer_name)
  end)

  -- Open a new tab and set the buffer
  vim.cmd("tabnew")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Wait for buffer to fully load, then run CopilotChat
  vim.defer_fn(function()
    -- Make sure we're still in the right buffer
    if vim.api.nvim_get_current_buf() == buf then
      -- Start with an empty context array
      local context = {}
      -- Add the specific files from the diff first
      for _, file in ipairs(files) do
        table.insert(context, 'file:' .. file)
      end
      -- Add the default file patterns afterward
      table.insert(context, 'files:*/**/*.scala')
      table.insert(context, 'files:*/**/*.md')

      -- Apply the specified prompt with extracted files as context
      require("CopilotChat").ask(prompt, {
        buffer = buf,
        context = context,
      })
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

local select = require("CopilotChat.select")

require("CopilotChat").setup {
  model = 'claude-3.7-sonnet-thought', -- default model
  sticky = {'#files:*/**/*.scala', '#files:*/**/*.md'},
  selection = function(source)
    return select.visual(source) or select.buffer(source)
  end,
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
