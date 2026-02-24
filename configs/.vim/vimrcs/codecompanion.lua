local CONTEXT_MAX_NUMBER_FILES = 12

-- ============================================================================
-- GitLab Helper Functions (kept from your original setup)
-- ============================================================================

local function extract_issue_number(branch_name)
  local patterns = {
    "(%d+)%-",
    "%-(%d+)%-",
    "%-(%d+)$",
    "^(%d+)%-",
    "/(%d+)%-",
    "/issue%-(%d+)",
    "#(%d+)",
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

  local notes_cmd = string.format("glab api projects/:id/issues/%s/discussions 2>/dev/null", issue_number)
  local notes_output = vim.fn.system(notes_cmd)

  if vim.v.shell_error == 0 then
    local notes_ok, discussions_data = pcall(vim.json.decode, notes_output)
    if notes_ok and discussions_data and #discussions_data > 0 then
      context = context .. "**Comments:**\n"
      for i = #discussions_data, 1, -1 do
        local discussion = discussions_data[i]
        local notes = discussion.notes
        if notes then
          for j, note in ipairs(notes) do
            if note.body and note.body ~= "" and not note.system then
              local author_name = note.author and (note.author.name or note.author.username) or "Unknown"
              local prefix = j > 1 and "  - " or "- "
              context = context .. string.format("%s%s: %s\n", prefix, author_name, note.body)
            end
          end
        end
      end
    end
  end

  return context
end

local function get_gitlab_mr_info(branch_name)
  if not branch_name then return "" end

  local cmd = string.format("glab mr list --source-branch %s --output json 2>/dev/null", branch_name)
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return ""
  end

  local ok, mr_list = pcall(vim.json.decode, output)
  if not ok or not mr_list or #mr_list == 0 then return "" end

  local mr = mr_list[1]

  local context = string.format([[

## GitLab Merge Request !%s
**Title:** %s
**State:** %s
**Source Branch:** %s
**Target Branch:** %s
**Description:**
%s

]], mr.iid or "", mr.title or "", mr.state or "", mr.source_branch or "", mr.target_branch or "", mr.description or "")

  local notes_cmd = string.format("glab api projects/:id/merge_requests/%s/discussions 2>/dev/null", mr.iid or "")
  local notes_output = vim.fn.system(notes_cmd)

  if vim.v.shell_error == 0 then
    local notes_ok, discussions_data = pcall(vim.json.decode, notes_output)
    if notes_ok and discussions_data and #discussions_data > 0 then
      context = context .. "**Comments:**\n"
      for i = #discussions_data, 1, -1 do
        local discussion = discussions_data[i]
        local notes = discussion.notes
        if notes then
          for j, note in ipairs(notes) do
            if note.body and note.body ~= "" and not note.system then
              local author_name = note.author and (note.author.name or note.author.username) or "Unknown"
              local prefix = j > 1 and "  - " or "- "
              context = context .. string.format("%s%s: %s\n", prefix, author_name, note.body)
            end
          end
        end
      end
    end
  end

  return context
end

local function get_current_branch()
  local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error == 0 and branch ~= "" then
    return branch
  end
  return nil
end

local function get_gitlab_context_for_branch(branch_name)
  local context = ""
  if branch_name then
    context = context .. get_gitlab_mr_info(branch_name)
    local issue_number = extract_issue_number(branch_name)
    context = context .. get_gitlab_issue_info(issue_number)
  end
  return context
end

-- ============================================================================
-- Git Diff Helper Functions (ported from CopilotChat config)
-- ============================================================================

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

    if a:ArgLead =~ '\.\.\.\|\.\..'
      let parts = split(a:ArgLead, '\.\.\.\|\.\.')
      if len(parts) > 1
        let branch_prefix = parts[1]
        let local_branches = systemlist('git branch --format="%(refname:short)" 2>/dev/null')
        let remote_branches = systemlist('git branch -r --format="%(refname:short)" 2>/dev/null')
        call filter(local_branches, 'v:val =~ "^" . branch_prefix')
        call filter(remote_branches, 'v:val =~ "^origin/" . branch_prefix')
        call map(remote_branches, 'substitute(v:val, "^origin/", "", "")')
        let operator = a:ArgLead =~ '\.\.\.' ? '...' : '..'
        let first_part = parts[0]
        let completions = []
        for branch in local_branches + remote_branches
          call add(completions, first_part . operator . branch)
        endfor
        return completions
      endif
    endif

    if a:ArgLead =~ '^[^-]' || a:ArgLead == ''
      let file_completions = glob(a:ArgLead . '*', 0, 1)
      call map(file_completions, 'isdirectory(v:val) ? v:val . "/" : v:val')
      if a:ArgLead !~ '/' && a:ArgLead !~ '\\'
        let local_branches = systemlist('git branch --format="%(refname:short)" 2>/dev/null')
        call filter(local_branches, 'v:val =~ "^" . a:ArgLead')
        call extend(file_completions, local_branches)
        let remote_branches = systemlist('git branch -r --format="%(refname:short)" 2>/dev/null')
        call filter(remote_branches, 'v:val =~ "^origin/" . a:ArgLead')
        call map(remote_branches, 'substitute(v:val, "^origin/", "", "")')
        call extend(file_completions, remote_branches)
      endif
      if a:ArgLead == ''
        let git_files = systemlist('git ls-files 2>/dev/null')
        call extend(file_completions, git_files)
      endif
      call filter(file_completions, 'v:val =~ "^" . a:ArgLead')
      let file_completions = uniq(sort(file_completions))
      return file_completions
    endif

    return filter(copy(options), 'v:val =~ "^" . a:ArgLead')
  endfunction
]])

local function branch_exists_locally(branch_name)
  if not branch_name then return false end
  local cmd = string.format("git show-ref --verify --quiet refs/heads/%s", branch_name)
  return vim.fn.system(cmd) == "" and vim.v.shell_error == 0
end

local function remote_branch_exists(branch_name, remote)
  if not branch_name then return false end
  remote = remote or "origin"
  local cmd = string.format("git show-ref --verify --quiet refs/remotes/%s/%s", remote, branch_name)
  return vim.fn.system(cmd) == "" and vim.v.shell_error == 0
end

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
    return branch_name
  end
end

local function resolve_diff_input(input)
  local resolved_input = input
  if not input or input == "" then
    return resolved_input
  end

  local modified = false

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

  return resolved_input
end

local function extract_branch_from_input(input)
  local branch_name = nil
  if input and input ~= "" then
    local source_branch = nil
    if input:match("%.%.%.") then
      source_branch = input:match("%.%.%.([^%s]+)")
      if input:match("%.%.%.$") then
        source_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
        if vim.v.shell_error ~= 0 then source_branch = nil end
      end
    elseif input:match("%.%.") then
      source_branch = input:match("%.%.([^%s]+)")
    elseif input:match("^%.%.%.") then
      source_branch = input:match("^%.%.%.([^%s]+)")
    else
      source_branch = input:match("^([^%s%-%.]+)$")
    end
    branch_name = source_branch
  else
    branch_name = get_current_branch()
  end
  return branch_name
end

local function open_codecompanion_chat(prompt, sticky_context)
  vim.cmd("CodeCompanionChat")

  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    local lines = {}

    -- Add sticky context lines (files as variables)
    if sticky_context and #sticky_context > 0 then
      table.insert(lines, "> Context:")
      for _, ctx in ipairs(sticky_context) do
        table.insert(lines, "> " .. ctx)
      end
      table.insert(lines, "") -- Add an empty line after context
    end

    -- Add prompt
    for _, line in ipairs(vim.split(prompt, "\n")) do
      table.insert(lines, line)
    end

    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false
    )
  end, 200)
end

local function extract_diff_files(diff_output)
  local files = {}
  for line in diff_output:gmatch("[^\r\n]+") do
    local file_path = line:match("^%+%+%+ b/(.+)$") or line:match("^%-%-%-% a/(.+)$")
    if file_path and file_path ~= "/dev/null" and not vim.tbl_contains(files, file_path) then
      table.insert(files, file_path)
      if #files > CONTEXT_MAX_NUMBER_FILES then
        return {}
      end
    end
  end
  return files
end

local function git_diff_with_codecompanion(prompt)
  local input = vim.fn.input({
    prompt = "Git diff arguments (leave empty for default): ",
    cancelreturn = "__CANCEL__",
    completion = "customlist,GitDiffCompletion"
  })

  if input == "__CANCEL__" then
    vim.notify("Git diff operation cancelled", vim.log.levels.INFO)
    return
  end

  local resolved_input = resolve_diff_input(input)
  local cmd = "git diff " .. (resolved_input ~= "" and resolved_input or "")

  local diff_output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Git diff failed: " .. diff_output, vim.log.levels.ERROR)
    return
  end

  if diff_output == "" then
    vim.notify("Git diff is empty, nothing to review", vim.log.levels.WARN)
    return
  end

  -- Extract changed files for context
  local files = extract_diff_files(diff_output)
  local sticky_context = {}
  for _, file in ipairs(files) do
    table.insert(sticky_context, "- <file>" .. file .. "</file>")
  end

  -- Extract branch info for GitLab context
  local branch_name = extract_branch_from_input(input)
  local gitlab_context = ""
  if branch_name then
    gitlab_context = get_gitlab_context_for_branch(branch_name)
    local issue_number = extract_issue_number(branch_name)
    vim.notify(string.format("Branch: '%s', Issue: '%s', GitLab context length: %d",
      branch_name or "nil", issue_number or "nil", #gitlab_context), vim.log.levels.INFO)
  end

  -- Build the full prompt
  local full_prompt = prompt
  if gitlab_context ~= "" then
    full_prompt = prompt
      .. "\n\n" .. string.rep("=", 30) .. " GITLAB CONTEXT " .. string.rep("=", 30)
      .. "\n```markdown"
      .. gitlab_context
      .. "```\n"
      .. string.rep("=", 30) .. " END GITLAB CONTEXT " .. string.rep("=", 30)
  end

  full_prompt = full_prompt
    .. "\n\n" .. string.rep("=", 30) .. " GIT DIFF " .. string.rep("=", 30)
    .. "\n```diff\n" .. diff_output .. "\n```\n"
    .. string.rep("=", 30) .. " END GIT DIFF " .. string.rep("=", 30)

  open_codecompanion_chat(full_prompt, sticky_context)
end

local function implement_gitlab_issue()
  local issue_number = vim.fn.input({
    prompt = "Enter GitLab issue number: ",
    cancelreturn = "__CANCEL__",
  })

  if issue_number == "__CANCEL__" or issue_number == "" then
    vim.notify("GitLab issue implementation cancelled", vim.log.levels.INFO)
    return
  end

  local issue_info = get_gitlab_issue_info(issue_number)

  if issue_info == "" then
    vim.notify("Failed to fetch GitLab issue #" .. issue_number, vim.log.levels.ERROR)
    return
  end

  local prompt = "Based on this GitLab issue, please provide a detailed implementation plan and suggest the necessary code changes to implement this feature. Include file modifications, new files that need to be created, and any architectural considerations."
    .. "\n\n" .. string.rep("=", 30) .. " GITLAB ISSUE CONTEXT " .. string.rep("=", 30)
    .. "\n```markdown\n"
    .. issue_info
    .. "```\n"
    .. string.rep("=", 30) .. " END GITLAB ISSUE CONTEXT " .. string.rep("=", 30)

  open_codecompanion_chat(prompt)
end

-- ============================================================================
-- CodeCompanion Setup
-- ============================================================================

require("codecompanion").setup({
  opts = {
    log_level = "DEBUG",
  },
  adapters = {
    copilot = function()
      return require("codecompanion.adapters").extend("copilot", {})
    end,
  },
  interactions = {
    chat = {
      adapter = {
        name = "copilot",
        model = "gpt-5-mini",
      },
      keymaps = {
        close = {
          modes = { n = "q" },
        },
        stop = {
          modes = { n = "<C-c>" },
        },
      },
    },
    inline = {
      adapter = "copilot",
    },
  },
  prompt_library = {},
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
      },
    },
  },
})

require("img-clip").setup({
  filetypes = {
    codecompanion = {
      prompt_for_file_name = false,
      template = "[Image]($FILE_PATH)",
      use_absolute_path = true,
    },
  },
})

-- ============================================================================
-- Keymaps
-- ============================================================================

local map = vim.keymap.set

map({ "n", "v" }, "<leader>zc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle chat" })
map({ "n", "v" }, "<leader>za", "<cmd>CodeCompanionActions<cr>", { desc = "Action palette" })
map("n", "<leader>zm", "<cmd>CodeCompanion /commit<cr>", { desc = "Commit message" })
map("n", "<leader>zdr", function()
  git_diff_with_codecompanion(
    "Review this git diff and suggest improvements. If given access, use the issue and merge/pull request information to properly check if everything was done and if all concerns were taken into considerations. If a change doesn't fit the style of how the rest of the codebase is implemented also point that out. Don't suggest fixes for things that weren't done as part of the diff."
  )
end, { noremap = true, silent = true, desc = "Review git diff with GitLab" })
map("n", "<leader>zd", function()
  git_diff_with_codecompanion("Explain this git diff")
end, { noremap = true, silent = true, desc = "Explain this git diff. If it is a bigger diff, talk about the different parts of the codebase it touches and how the changes affect how things interact. If possible, be visual." })
map("n", "<leader>zgi", function()
  implement_gitlab_issue()
end, { noremap = true, silent = true, desc = "Implement GitLab issue" })

-- Add buffer to current chat (useful for adding context)
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add selection to chat" })
