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

-- Function to extract issue number from branch name
local function extract_issue_number(branch_name)
  -- Common patterns for issue numbers in branch names
  -- Examples: feature/123-description, fix/issue-456, 123-feature, etc.
  local patterns = {
    "(%d+)%-",     -- 123-description
    "%-(%d+)%-",   -- prefix-123-description
    "%-(%d+)$",    -- prefix-123
    "^(%d+)%-",    -- 123-description
    "/(%d+)%-",    -- feature/123-description
    "/issue%-(%d+)", -- feature/issue-123
    "#(%d+)",      -- feature-#123
  }

  for _, pattern in ipairs(patterns) do
    local issue_num = branch_name:match(pattern)
    if issue_num then
      return issue_num
    end
  end

  return nil
end

local function get_gitlab_issue_info(issue_number)
  if not issue_number then return "" end

  local cmd = string.format("glab issue view %s --output json 2>/dev/null", issue_number)
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return ""
  end

  local ok, issue_data = pcall(vim.json.decode, output)
  if not ok then return "" end

  local context = string.format([[

## GitLab Issue #%s
**Title:** %s
**State:** %s
**Description:**
%s

]], issue_number, issue_data.title or "", issue_data.state or "", issue_data.description or "")

  -- Fetch comments separately using glab api
  local notes_cmd = string.format("glab api projects/:id/issues/%s/notes 2>/dev/null", issue_number)
  local notes_output = vim.fn.system(notes_cmd)

  if vim.v.shell_error == 0 then
    local notes_ok, notes_data = pcall(vim.json.decode, notes_output)
    if notes_ok and notes_data and #notes_data > 0 then
      context = context .. "**Comments:**\n"
      for _, note in ipairs(notes_data) do
        if note.body and note.body ~= "" and not note.system then
          local author_name = "Unknown"
          if note.author and note.author.name then
            author_name = note.author.name
          elseif note.author and note.author.username then
            author_name = note.author.username
          end
          context = context .. string.format("- %s: %s\n", author_name, note.body)
        end
      end
    end
  end

  return context
end

-- Function to get GitLab MR information for a branch
local function get_gitlab_mr_info(branch_name)
  if not branch_name then return "" end

  local cmd = string.format("glab mr list --source-branch %s --output json 2>/dev/null", branch_name)
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return ""
  end

  local ok, mr_list = pcall(vim.json.decode, output)
  if not ok or not mr_list or #mr_list == 0 then return "" end

  local mr = mr_list[1] -- Get the first MR

  local context = string.format([[

## GitLab Merge Request !%s
**Title:** %s
**State:** %s
**Source Branch:** %s
**Target Branch:** %s
**Description:**
%s

]], mr.iid or "", mr.title or "", mr.state or "", mr.source_branch or "", mr.target_branch or "", mr.description or "")

  return context
end

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

  -- Extract branch information for GitLab context
  local gitlab_context = ""

  -- Try to extract branch name from git diff input
  local branch_name = nil
  if input and input ~= "" then
    -- Handle various git diff target patterns
    local target_branch = nil
    local source_branch = nil

    -- Pattern: main...feature-branch (three dots)
    if input:match("%.%.%.") then
      source_branch = input:match("%.%.%.([^%s]+)")
      target_branch = input:match("([^%s%.]+)%.%.%.")

      -- Pattern: main... (current branch is the feature branch)
      if input:match("%.%.%.$") then
        source_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
        if vim.v.shell_error ~= 0 then source_branch = nil end
      end
    -- Pattern: main..feature-branch (two dots)
    elseif input:match("%.%.") then
      source_branch = input:match("%.%.([^%s]+)")
      target_branch = input:match("([^%s%.]+)%.%.")
    -- Pattern: ...feature-branch (comparing from HEAD to feature-branch)
    elseif input:match("^%.%.%.") then
      source_branch = input:match("^%.%.%.([^%s]+)")
    else
      -- Single branch name or other format
      source_branch = input:match("^([^%s%-%.]+)$")
    end

    -- Use source branch (the feature branch) for GitLab context
    branch_name = source_branch

    -- Debug output to help troubleshoot
    vim.notify(string.format("Input: '%s', Extracted branch: '%s'", input, branch_name or "nil"), vim.log.levels.INFO)
  else
    -- Get current branch if no input provided
    local current_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
    if vim.v.shell_error == 0 and current_branch ~= "" then
      branch_name = current_branch
    end
  end

  if branch_name then
    -- Get GitLab MR information
    gitlab_context = gitlab_context .. get_gitlab_mr_info(branch_name)

    -- Extract issue number and get issue information
    local issue_number = extract_issue_number(branch_name)
    gitlab_context = gitlab_context .. get_gitlab_issue_info(issue_number)

    -- Debug output
    vim.notify(string.format("Branch: '%s', Issue: '%s', GitLab context length: %d",
      branch_name or "nil", issue_number or "nil", #gitlab_context), vim.log.levels.INFO)
  end

  -- Create buffer name based on the git command with timestamp to avoid naming conflicts
  local timestamp = os.time()
  local buffer_name = "[Git] " .. cmd .. " " .. timestamp

  -- Create a new buffer for the diff output with GitLab context
  local full_content = diff_output
  if gitlab_context ~= "" then
    full_content = gitlab_context .. "\n" .. string.rep("=", 80) .. "\n" .. diff_output
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(full_content, "\n"))
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
      table.insert(context, 'files:*/**/*.md')
      table.insert(context, 'filenames:*/**/*.scala')
      table.insert(context, 'files:*/**/*.yaml')
      table.insert(context, 'files:*/**/*.conf')

      -- Apply the specified prompt with extracted files as context
      require("CopilotChat").ask(prompt, {
        buffer = buf,
        context = context,
      })
    end
  end, 300)
end

-- Copy of '#file' completion from CopilotChat
-- https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/lua/CopilotChat/config/contexts.lua
local utils = require('CopilotChat.utils')
local function file_completion(callback, source)
  local files = utils.scan_dir(source.cwd(), {
    max_count = 0,
  })

  utils.schedule_main()
  vim.ui.select(files, {
    prompt = 'Select a file> ',
  }, callback)
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
local chat = require("CopilotChat")

chat.setup {
  model = 'claude-sonnet-4', -- default model
  sticky = {'#files:*/**/*.md', '#filenames:*/**/*.scala', '#files:*/**/*.yaml', '#files:*/**/*.conf'},
selection = function(source)
    return select.visual(source) or select.buffer(source)
  end,

  contexts = {
    files = {
      input = file_completion,
    },
    filenames = {
      input = file_completion,
    }
  },

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
