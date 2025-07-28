local mcp = require('mcphub')

mcp.setup({
  --- `mcp-hub` binary related options-------------------
  config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to MCP Servers config file (will create if not exists)
  port = 37373, -- The port `mcp-hub` server listens to
  shutdown_delay = 60 * 10 * 000, -- Delay in ms before shutting down the server when last instance closes (default: 10 minutes)
  use_bundled_binary = false, -- Use local `mcp-hub` binary (set this to true when using build = "bundled_build.lua")
  mcp_request_timeout = 60000, --Max time allowed for a MCP tool or resource to execute in milliseconds, set longer for long running tasks

  ---Chat-plugin related options-----------------
  auto_approve = false, -- Auto approve mcp tool calls
  auto_toggle_mcp_servers = true, -- Let LLMs start and stop MCP servers automatically
  extensions = {
      avante = {
          make_slash_commands = true, -- make /slash commands from MCP server prompts
      }
  },

  --- Plugin specific options-------------------
  native_servers = {}, -- add your custom lua native servers here
  ui = {
      window = {
          width = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
          height = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
          align = "center", -- "center", "top-left", "top-right", "bottom-left", "bottom-right", "top", "bottom", "left", "right"
          relative = "editor",
          zindex = 50,
          border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
      },
      wo = { -- window-scoped options (vim.wo)
          winhl = "Normal:MCPHubNormal,FloatBorder:MCPHubBorder",
      },
  },
  on_ready = function(hub)
      -- Called when hub is ready
  end,
  on_error = function(err)
      -- Called on errors
  end,
  log = {
      level = vim.log.levels.WARN,
      to_file = false,
      file_path = nil,
      prefix = "MCPHub",
  },
})

-- Integrate with CopilotChat.nvim
local chat = require("CopilotChat")
mcp.on({ "servers_updated", "tool_list_changed", "resource_list_changed" }, function()
	local hub = mcp.get_hub_instance()
	if not hub then
		return
	end

	local async = require("plenary.async")
	local call_tool = async.wrap(function(server, tool, input, callback)
		hub:call_tool(server, tool, input, {
			callback = function(res, err)
				callback(res, err)
			end,
		})
	end, 4)

	local access_resource = async.wrap(function(server, uri, callback)
		hub:access_resource(server, uri, {
			callback = function(res, err)
				callback(res, err)
			end,
		})
	end, 3)

	for name, tool in pairs(chat.config.functions) do
		if tool.id and tool.id:sub(1, 3) == "mcp" then
			chat.config.functions[name] = nil
		end
	end
	local resources = hub:get_resources()
	for _, resource in ipairs(resources) do
		local name = resource.name:lower():gsub(" ", "_"):gsub(":", "")
		chat.config.functions[name] = {
			id = "mcp:" .. resource.server_name .. ":" .. name,
			uri = resource.uri,
			description = type(resource.description) == "string" and resource.description or "",
			resolve = function()
				local res, err = access_resource(resource.server_name, resource.uri)
				if err then
					error(err)
				end

				res = res or {}
				local result = res.result or {}
				local content = result.contents or {}
				local out = {}

				for _, message in ipairs(content) do
					if message.text then
						table.insert(out, {
							uri = message.uri,
							data = message.text,
							mimetype = message.mimeType,
						})
					end
				end

				return out
			end,
		}
	end

	local tools = hub:get_tools()
	for _, tool in ipairs(tools) do
		chat.config.functions[tool.name] = {
			id = "mcp:" .. tool.server_name .. ":" .. tool.name,
			group = tool.server_name,
			description = tool.description,
			schema = tool.inputSchema,
			resolve = function(input)
				local res, err = call_tool(tool.server_name, tool.name, input)
				if err then
					error(err)
				end

				res = res or {}
				local result = res.result or {}
				local content = result.content or {}
				local out = {}

				for _, message in ipairs(content) do
					if message.type == "text" then
						table.insert(out, {
							data = message.text,
						})
					elseif message.type == "resource" and message.resource and message.resource.text then
						table.insert(out, {
							uri = message.resource.uri,
							data = message.resource.text,
							mimetype = message.resource.mimeType,
						})
					end
				end

				return out
			end,
		}
	end
end)
