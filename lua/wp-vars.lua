local Job = require("plenary.job")

local registered = false

local defaults = {
	cmp_filetypes = { "css", "scss" },
	preset_mappings = {
		{ path = "color.palette", preset_type = "color", value_key = "color" },
		{ path = "spacing.spacingSizes", preset_type = "spacing", value_key = "size", sort_key = "slug" },
		{ path = "typography.fontSizes", preset_type = "font-size", value_key = "size" },
		{ path = "typography.fontFamilies", preset_type = "font-family", value_key = "fontFamily" },
	},
}

local M = {}
M.setup = function(cfg)
	M.__conf = vim.tbl_deep_extend("keep", cfg or {}, defaults)
	if registered then
		return
	end
	registered = true

	local function to_absolute_paths(relative_paths)
		local paths = {}
		for _, path in ipairs(relative_paths) do
			if vim.startswith(path, "/") then
				table.insert(paths, path)
			else
				table.insert(paths, vim.loop.cwd() .. "/" .. path)
			end
		end
		return paths
	end

	local function find_theme_files(args)
		local job = Job:new({
			command = "fd",
			args = args,
		})
		job:sync()
		return job:result()
	end

	local function get_theme_json_paths()
		-- Auto-detect from package.json
		local package_job = Job:new({
			command = "cat",
			args = { vim.loop.cwd() .. "/package.json" },
		})
		package_job:sync()

		local package_content = table.concat(package_job:result(), "\n")
		if #package_content == 0 then
			-- No package.json, search for all theme.json files.
			local all_results = find_theme_files({ "-t", "f", "theme.json", "." })
			return to_absolute_paths(all_results)
		end

		local ok, package_data = pcall(vim.json.decode, package_content)
		if not ok or not package_data or not package_data.name then
			-- Invalid package.json, search for all theme.json files.
			local all_results = find_theme_files({ "-t", "f", "theme.json", "." })
			return to_absolute_paths(all_results)
		end

		-- First, try to find theme by package name.
		local name_results = find_theme_files({ "-t", "f", "-p", package_data.name .. "/theme.json", "." })
		if #name_results > 0 then
			return to_absolute_paths(name_results)
		end

		-- Fallback, search for all theme.json files,
		local all_results = find_theme_files({ "-t", "f", "theme.json", "." })
		return to_absolute_paths(all_results)
	end

	local function parse_theme_json()
		local css_vars = {}
		local theme_paths = get_theme_json_paths()

		for _, theme_json_path in pairs(theme_paths) do
			local read_job = Job:new({
				command = "cat",
				args = { theme_json_path },
			})
			read_job:sync()

			local content = table.concat(read_job:result(), "\n")
			local ok, json_data = pcall(vim.json.decode, content)

			if ok and json_data and json_data.settings then
				-- Parse config presets.
				for _, mapping in pairs(M.__conf.preset_mappings) do
					local data = json_data.settings
					for key in mapping.path:gmatch("[^.]+") do
						data = data and data[key]
					end

					if data then
						for _, item in ipairs(data) do
							if item.slug then
								local css_var = "--wp--preset--" .. mapping.preset_type .. "--" .. item.slug
								local sort_key = mapping.sort_key and item[mapping.sort_key] or (item.name or item.slug)
								table.insert(css_vars, {
									var = css_var,
									value = item[mapping.value_key] or "",
									name = item.name or item.slug,
									sort_key = sort_key,
								})
							end
						end
					end
				end
			end
		end

		return css_vars
	end

	vim.schedule(function()
		local has_cmp, cmp = pcall(require, "cmp")
		if not has_cmp then
			return
		end

		local source = {}

		source.new = function()
			return setmetatable({}, { __index = source })
		end

		source.get_trigger_characters = function()
			return { "-" }
		end

		source.complete = function(self, request, callback)
			local is_theme_json = request.context.filetype == "json" and vim.fn.expand("%:t") == "theme.json"
			local is_allowed_filetype = vim.tbl_contains(M.__conf.cmp_filetypes, request.context.filetype)

			if not (is_allowed_filetype or is_theme_json) then
				callback({ isIncomplete = true })
				return
			end

			local input = string.sub(request.context.cursor_before_line, request.offset - 1)
			local prefix = string.sub(request.context.cursor_before_line, 1, request.offset - 1)

			if vim.startswith(input, "-") and vim.endswith(prefix, "--") then
				local css_vars = parse_theme_json()
				local items = {}

				for _, css_var_data in pairs(css_vars) do
					table.insert(items, {
						word = css_var_data.var,
						label = css_var_data.var,
						kind = 21,
						menu = "wp-var",
						documentation = css_var_data.value .. " (" .. css_var_data.name .. ")",
						insertText = css_var_data.var,
						sortText = css_var_data.sort_key,
					})
				end

				callback({
					items = items,
					isIncomplete = false,
				})
			else
				callback({ isIncomplete = true })
			end
		end

		cmp.register_source("wp_vars", source.new())
	end)
end

return M
