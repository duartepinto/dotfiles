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

      if #notes_data > 0 then
        context = context .. "**Comments:**\n"
      end
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

  -- Fetch comments separately using glab api
  local notes_cmd = string.format("glab api projects/:id/merge_requests/%s/notes 2>/dev/null", mr.iid or "")
  local notes_output = vim.fn.system(notes_cmd)

  if vim.v.shell_error == 0 then
    local notes_ok, notes_data = pcall(vim.json.decode, notes_output)
    if notes_ok and notes_data and #notes_data > 0 then

      if #notes_data > 0 then
        context = context .. "**Comments:**\n"
      end
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

-- Helper function to execute CopilotChat after buffer loads
local function execute_copilot_chat_on_buffer(buffer_name, buffer_content,prompt, context)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(buffer_content, "\n"))
  vim.api.nvim_buf_set_option(buf, "filetype", "md")

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
    -- Verify we're still in the correct buffer and window
    if vim.api.nvim_get_current_buf() == buf then
      local chat = require("CopilotChat")
      chat.reset()
      chat.close()
      chat.set_source(win)

      -- DEBUG: Print buffer info before ask
      -- local current_buf = vim.api.nvim_get_current_buf()
      -- local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
      -- local current_win = vim.api.nvim_get_current_win()
      -- local win_buf = vim.api.nvim_win_get_buf(current_win)
      -- local source_info = chat.get_source()

      -- vim.notify(string.format(
        -- "DEBUG:\nExpected buf: %d (%s)\nExpected win: %d\nCurrent buf: %d (%s)\nCurrent win: %d\nWin's buf: %d\nSource bufnr: %s\nSource winnr: %s",
        -- buf, buffer_name,
        -- win,
        -- current_buf, current_buf_name,
        -- current_win, win_buf,
        -- source_info.bufnr or "nil",
        -- source_info.winnr or "nil"
      -- ), vim.log.levels.INFO)

      chat.ask(prompt, { sticky = context })
    end
  end, 300)
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

  -- Function to check if a branch exists locally
  local function branch_exists_locally(branch_name)
    if not branch_name then return false end
    local cmd = string.format("git show-ref --verify --quiet refs/heads/%s", branch_name)
    return vim.fn.system(cmd) == "" and vim.v.shell_error == 0
  end

  -- Function to check if a remote branch exists
  local function remote_branch_exists(branch_name, remote)
    if not branch_name then return false end
    remote = remote or "origin"
    local cmd = string.format("git show-ref --verify --quiet refs/remotes/%s/%s", remote, branch_name)
    return vim.fn.system(cmd) == "" and vim.v.shell_error == 0
  end

  -- Function to resolve branch reference, preferring local but falling back to remote
  local function resolve_branch_ref(branch_name, remote)
    if not branch_name then return branch_name end
    remote = remote or "origin"

    if branch_exists_locally(branch_name) then
      return branch_name
    elseif remote_branch_exists(branch_name, remote) then
      vim.notify(string.format("Local branch '%s' not found, using remote '%s/%s'", branch_name, remote, branch_name), vim.log.levels.INFO)
      return remote .. "/" .. branch_name
    else
      vim.notify(string.format("Branch '%s' not found locally or on remote '%s'", branch_name, remote), vim.log.levels.WARN)
      return branch_name -- Return original and let git handle the error
    end
  end

  -- Process the input to resolve any branch references
  local resolved_input = input
  if input and input ~= "" then
    -- Handle various git diff patterns and resolve branch names
    local modified = false

    -- Pattern: main...feature-branch (three dots)
    if input:match("%.%.%.") then
      local target_branch = input:match("([^%s%.]+)%.%.%.")
      local source_branch = input:match("%.%.%.([^%s]+)")

      if target_branch then
        local resolved_target = resolve_branch_ref(target_branch)
        if resolved_target ~= target_branch then
          resolved_input = resolved_input:gsub(vim.pesc(target_branch) .. "%.%.%.", resolved_target .. "...")
          modified = true
        end
      end

      if source_branch then
        local resolved_source = resolve_branch_ref(source_branch)
        if resolved_source ~= source_branch then
          resolved_input = resolved_input:gsub("%.%.%." .. vim.pesc(source_branch), "..." .. resolved_source)
          modified = true
        end
      end
    -- Pattern: main..feature-branch (two dots)
    elseif input:match("%.%.") then
      local target_branch = input:match("([^%s%.]+)%.%.")
      local source_branch = input:match("%.%.([^%s]+)")

      if target_branch then
        local resolved_target = resolve_branch_ref(target_branch)
        if resolved_target ~= target_branch then
          resolved_input = resolved_input:gsub(vim.pesc(target_branch) .. "%.%.", resolved_target .. "..")
          modified = true
        end
      end

      if source_branch then
        local resolved_source = resolve_branch_ref(source_branch)
        if resolved_source ~= source_branch then
          resolved_input = resolved_input:gsub("%.%." .. vim.pesc(source_branch), ".." .. resolved_source)
          modified = true
        end
      end
    -- Pattern: ...feature-branch (comparing from HEAD to feature-branch)
    elseif input:match("^%.%.%.") then
      local source_branch = input:match("^%.%.%.([^%s]+)")
      if source_branch then
        local resolved_source = resolve_branch_ref(source_branch)
        if resolved_source ~= source_branch then
          resolved_input = "..." .. resolved_source
          modified = true
        end
      end
    else
      -- Single branch name or other format
      local single_branch = input:match("^([^%s%-%.]+)$")
      if single_branch then
        local resolved_branch = resolve_branch_ref(single_branch)
        if resolved_branch ~= single_branch then
          resolved_input = resolved_branch
          modified = true
        end
      end
    end

    if modified then
      vim.notify(string.format("Resolved git diff command: git diff %s", resolved_input), vim.log.levels.INFO)
    end
  end

  local cmd = "git diff " .. (resolved_input ~= "" and resolved_input or "")

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
      local absolute_path = vim.fn.fnamemodify(file_path, ":p")
      table.insert(files, absolute_path)

      -- Return nil if more than 7 files
      if #files > 7 then
        files = {}
        break
      end
    end
  end

  -- Extract branch information for GitLab context
  local gitlab_context = ""

  -- Try to extract branch name from git diff input (use original input for branch name extraction)
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
  local full_content = ""
  if gitlab_context ~= "" then
    full_content = gitlab_context .. "\n" .. string.rep("=", 80)
  end

  -- Prepare context for CopilotChat
  local context = {}
  for _, file in ipairs(files) do
    table.insert(context, '#file:' .. file)
  end
  table.insert(context, '#gitdiff:' .. (resolved_input ~= "" and resolved_input or ""))

  -- Execute CopilotChat after buffer loads
  execute_copilot_chat_on_buffer(buffer_name, full_content, prompt, context)
end

-- Adaptation of the original '#file' completion from CopilotChat
-- https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/lua/CopilotChat/config/contexts.lua
local utils = require('CopilotChat.utils')
local function file_completion(callback, source)
  local files = utils.scan_dir(source.cwd(), {
    max_count = 0,
  })

  local cwd = source.cwd()
  local relative_files = {}
  for _, file in ipairs(files) do
    local relative_path = vim.fn.fnamemodify(file, ':~:.')
    if relative_path:sub(1, 1) ~= '/' then
      table.insert(relative_files, relative_path)
    else
      -- Fallback: manually calculate relative path
      table.insert(relative_files, file:gsub('^' .. vim.pesc(cwd .. '/'), ''))
    end
  end

  utils.schedule_main()
  vim.ui.select(relative_files, {
    prompt = 'Select a file> ',
  }, callback)
end

-- Function to implement GitLab issue with CopilotChat integration
local function implement_gitlab_issue()
  -- Get issue number from user with abort on escape
  local issue_number = vim.fn.input({
    prompt = "Enter GitLab issue number: ",
    cancelreturn = "__CANCEL__",  -- Special value to detect cancellation
  })

  -- Check if user canceled input
  if issue_number == "__CANCEL__" or issue_number == "" then
    vim.notify("GitLab issue implementation cancelled", vim.log.levels.INFO)
    return
  end

  -- Get GitLab issue information
  local issue_info = get_gitlab_issue_info(issue_number)

  if issue_info == "" then
    vim.notify("Failed to fetch GitLab issue #" .. issue_number, vim.log.levels.ERROR)
    return
  end

  -- Create buffer name with timestamp to avoid naming conflicts
  local timestamp = os.time()
  local buffer_name = "[GitLab Issue] #" .. issue_number .. " " .. timestamp

  execute_copilot_chat_on_buffer(
    buffer_name,
    issue_info,
    "Based on this GitLab issue, please provide a detailed implementation plan and suggest the necessary code changes to implement this feature. Include file modifications, new files that need to be created, and any architectural considerations.",
    nil
  )
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
map("n", "<leader>zgi", function()
  implement_gitlab_issue()
end, { noremap = true, silent = true, desc = "CopilotChat: Implement this issue" })

local select = require("CopilotChat.select")
local chat = require("CopilotChat")

chat.setup {
  model = 'claude-sonnet-4.5', -- default model
  sticky = {'@metals', '#buffer', '#glob:*/**/*.scala' },
  selection = 'visual',

  contexts = {
    file = {
      input = file_completion,
    },
    files = {
      input = file_completion,
    },
    filenames = {
      input = file_completion,
    },
  },

  --
  -- default mappings
  -- see config/mappings.lua for implementation
  mappings = {
    -- complete = {
      -- insert = '<Tab>',
    -- },
    -- close = {
      -- normal = 'q',
      -- insert = '<C-c>',
    -- },
    reset = {
      normal = 'gl',
      insert = '<C-l>',
    },
    -- submit_prompt = {
      -- normal = '<CR>',
      -- insert = '<C-s>',
    -- },
    -- toggle_sticky = {
      -- detail = 'Makes line under cursor sticky or deletes sticky line.',
      -- normal = 'gr',
    -- },
    -- accept_diff = {
      -- normal = '<C-y>',
      -- insert = '<C-y>',
    -- },
    -- jump_to_diff = {
      -- normal = 'gj',
    -- },
    -- quickfix_answers = {
      -- normal = 'gqa',
    -- },
    -- quickfix_diffs = {
      -- normal = 'gqd',
    -- },
    -- yank_diff = {
      -- normal = 'gy',
      -- register = '"', -- Default register to use for yanking
    -- },
    -- show_diff = {
      -- normal = 'gd',
      -- full_diff = false, -- Show full diff instead of unified diff when showing diff window
    -- },
    -- show_info = {
      -- normal = 'gi',
    -- },
    -- show_context = {
      -- normal = 'gc',
    -- },
    -- show_help = {
      -- normal = 'gh',
    -- },
  }
}
