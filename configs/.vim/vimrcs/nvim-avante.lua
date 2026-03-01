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
    if issue_num then return issue_num end
  end
  return nil
end

local function get_gitlab_issue_info(issue_number)
  if not issue_number then return "" end
  local cmd = string.format("glab issue view %s --output json 2>/dev/null", issue_number)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return "" end
  local ok, issue_data = pcall(vim.json.decode, output)
  if not ok then return "" end

  local context = string.format(
    "\n## GitLab Issue #%s\n**Title:** %s\n**State:** %s\n**Description:**\n%s\n\n",
    issue_number, issue_data.title or "", issue_data.state or "", issue_data.description or ""
  )

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
              local author_name = (note.author and (note.author.name or note.author.username)) or "Unknown"
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
  if vim.v.shell_error ~= 0 then return "" end
  local ok, mr_list = pcall(vim.json.decode, output)
  if not ok or not mr_list or #mr_list == 0 then return "" end

  local mr = mr_list[1]
  local context = string.format(
    "\n## GitLab Merge Request !%s\n**Title:** %s\n**State:** %s\n**Source Branch:** %s\n**Target Branch:** %s\n**Description:**\n%s\n\n",
    mr.iid or "", mr.title or "", mr.state or "", mr.source_branch or "", mr.target_branch or "", mr.description or ""
  )

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
              local author_name = (note.author and (note.author.name or note.author.username)) or "Unknown"
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

local function git_diff_ask(prompt_prefix)
  local input = vim.fn.input({
    prompt = "Git diff arguments (leave empty for default): ",
    cancelreturn = "__CANCEL__",
    completion = "customlist,GitDiffCompletion",
  })
  if input == "__CANCEL__" then
    vim.notify("Git diff operation cancelled", vim.log.levels.INFO)
    return
  end

  local cmd = "git diff " .. input
  local diff_output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Git diff failed: " .. diff_output, vim.log.levels.ERROR)
    return
  end

  -- Extract files from diff
  local CONTEXT_MAX_NUMBER_FILES = 12
  local files = {}
  for line in diff_output:gmatch("[^\r\n]+") do
    local file_path = line:match("^%+%+%+ b/(.+)$") or line:match("^%-%-%-  a/(.+)$")
    if file_path and not vim.tbl_contains(files, file_path) then
      table.insert(files, file_path)
      if #files > CONTEXT_MAX_NUMBER_FILES then
        files = {}
        break
      end
    end
  end

  -- Extract branch name for GitLab context
  local branch_name = nil
  if input ~= "" then
    branch_name = input:match("%.%.%.([^%s]+)") or input:match("%.%.([^%s]+)") or input:match("^([^%s%-%.]+)$")
  else
    local current = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
    if vim.v.shell_error == 0 and current ~= "" then branch_name = current end
  end

  local gitlab_context = ""
  if branch_name then
    gitlab_context = gitlab_context .. get_gitlab_mr_info(branch_name)
    local issue_number = extract_issue_number(branch_name)
    gitlab_context = gitlab_context .. get_gitlab_issue_info(issue_number)
  end

  local sep = string.rep("=", 28)
  local full_prompt = prompt_prefix
  if gitlab_context ~= "" then
    full_prompt = full_prompt
      .. "\n\n" .. sep .. " GITLAB CONTEXT " .. sep
      .. gitlab_context
      .. sep .. " END GITLAB CONTEXT " .. sep
  end
  full_prompt = full_prompt
    .. "\n\n" .. sep .. " GIT DIFF " .. sep
    .. "\n```diff\n" .. diff_output .. "\n```\n"
    .. sep .. " END GIT DIFF " .. sep

  local avante = require("avante")
  local api = require("avante.api")
  local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")

  local function set_files()
    local sidebar = avante.get()

    -- Remove current buffer from selection
    sidebar.file_selector:remove_selected_file(current_file)

    -- Add diff files to selection
    if #files > 0 then
      for _, file in ipairs(files) do
        local rel = vim.fn.fnamemodify(file, ":~:.")
        sidebar.file_selector:add_selected_file(rel)
      end
    end
  end

  local function submit_with_files()
    local sidebar = avante.get()
    if not sidebar or not sidebar.file_selector then
      vim.defer_fn(submit_with_files, 100)
      return
    end

    -- Remove current file and add only diff files
    set_files()

    -- Now submit the question with correct files in context. We use an autocmd because api.ask seems to ignore the file
    -- context and just setting the current files as context
    vim.api.nvim_exec_autocmds("User", {
      pattern = "AvanteInputSubmitted",
      data = { request = full_prompt },
    })

    -- Re-apply files after submission. This needs to happen because the sidebar resets selected files on submit, and
    -- we want to ensure the correct files are always selected for context.
    vim.defer_fn(set_files, 100)
  end

  -- Open sidebar with new chat but without question, then set files and submit
  api.ask({new_chat = true})
  submit_with_files()
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

  local sep = string.rep("=", 25)
  local prompt = "Based on this GitLab issue, please provide a detailed implementation plan and suggest the necessary code changes. Include file modifications, new files that need to be created, and any architectural considerations."
    .. "\n\n" .. sep .. " GITLAB ISSUE CONTEXT " .. sep
    .. issue_info
    .. sep .. " END GITLAB ISSUE CONTEXT " .. sep

  require("avante.api").ask({ question = prompt, new_chat = true })
end

-- Keymaps (using <leader>z prefix to match your old CopilotChat mappings)
map("n", "<leader>zc", "<cmd>AvanteToggle<cr>", { desc = "Avante: Toggle sidebar" })
map("n", "<leader>zt", "<cmd>AvanteAsk Please generate tests for this code<cr>", { desc = "Avante: Generate tests" })
map("n", "<leader>zm", function()
  require("avante.api").ask({ question = "Generate a conventional commit message for the staged changes." })
end, { desc = "Avante: Commit message" })
map("v", "<leader>zm", function()
  require("avante.api").ask({ question = "Generate a conventional commit message for the staged changes." })
end, { desc = "Avante: Commit message (visual)" })
map("n", "<leader>zdr", function()
  git_diff_ask(
    "Review this git diff and suggest improvements. Use any issue and MR information to check if everything was addressed. Point out style inconsistencies with the rest of the codebase. Don't suggest fixes for things not in the diff."
  )
end, { desc = "Avante: Review git diff" })
map("n", "<leader>zd", function()
  git_diff_ask("Explain this git diff. For larger diffs, describe the different parts of the codebase it touches and how the changes affect interactions. Be visual where possible.")
end, { desc = "Avante: Explain git diff" })
map("n", "<leader>zgi", implement_gitlab_issue, { desc = "Avante: Implement GitLab issue" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function(ev)
    map("n", "<leader>a+", function()
      require("avante.extensions.nvim_tree").add_file()
    end, { desc = "Select file in NvimTree", buffer = ev.buf })
    map("n", "<leader>a-", function()
      require("avante.extensions.nvim_tree").remove_file()
    end, { desc = "Deselect file in NvimTree", buffer = ev.buf })
  end,
})

require("avante").setup({
  provider = "copilot",
  providers = {
    copilot = {
      model = "gpt-5-mini",
    },
  },
  behaviour = {
    auto_suggestions = false,
    auto_apply_diff_after_generation = false,
  },
  windows = {
    position = "right",
    width = 35,
  },
  -- render-markdown integration
  file_types = { "markdown", "Avante" },
  mappings = {
    sidebar = {
      next_prompt = "]",
      prev_prompt = "[",
      close_from_input = { normal = "q", insert = "<C-c>" },
    },
  },
  selector = {
    exclude_auto_select = { "NvimTree" },
  },
  -- system_prompt as function ensures LLM always has latest MCP server state
  -- This is evaluated for every message, even in existing chats
  system_prompt = function()
    local hub = require("mcphub").get_hub_instance()
    return hub and hub:get_active_servers_prompt() or ""
  end,
  -- Using function prevents requiring mcphub before it's loaded
  custom_tools = function()
    return {
        require("mcphub.extensions.avante").mcp_tool(),
    }
  end,
})

-- render-markdown setup for Avante filetype
local ok, render_md = pcall(require, "render-markdown")
if ok then
  render_md.setup({
    file_types = {"Avante" },
  })
end

-- Restrict avante's cmp sources to only Avante buffers
local cmp_ok, cmp = pcall(require, "cmp")
if cmp_ok then
  cmp.setup.filetype({ "AvanteInput" }, {
    sources = cmp.config.sources({
      { name = "avante_commands" },
      { name = "avante_mentions" },
      { name = "avante_files" },
    }),
  })
end

