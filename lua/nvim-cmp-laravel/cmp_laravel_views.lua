local cmp = require("cmp")
local scandir = require("plenary.scandir")

local source = {}

function source.new()
	return setmetatable({}, { __index = source })
end

function source:complete(params, callback)
	if string.sub(params.context.cursor_before_line, params.offset - 8, params.offset - 1) == "return view('" then
		local views = source.get_laravel_views()

		local filtered_views = {}
		for _, view in ipairs(views) do
			if type(view.label) == "string" then
				table.insert(filtered_views, view)
			end
		end

		callback({ items = filtered_views, isIncomplete = true })
	else
		callback({ items = {}, isIncomplete = false })
	end
end

function source.get_laravel_views()
	local views = {}
	local root_path = vim.fn.getcwd()
	local views_path = root_path .. "/resources/views"

	local files, _, _ = scandir.scan_dir(views_path, { hidden = false, depth = 10 })

	for _, file in ipairs(files) do
		if file.type == "file" and file.name:match("%.blade%.php$") then
			local relative_path = vim.fn.fnamemodify(file.path, ":~:.")
			local view_name = string.gsub(relative_path, "/", "."):sub(2, -11) -- Convert path to view name
			table.insert(views, {
				label = "view('" .. tostring(view_name) .. "')",
				kind = cmp.lsp.CompletionItemKind.laravel_views,
			})
		end
	end

	return views
end

-- Rest van de code blijft hetzelfde...
function source.get_trigger_characters()
	return { "'" }
end

-- Deze functie wordt gebruikt om de source te identificeren (optioneel)
function source.is_available()
	return vim.bo.filetype == "php" and source.has_laravel_files()
end

-- Controleer of bepaalde Laravel-bestanden aanwezig zijn in de huidige werkdirectory
function source.has_laravel_files()
	local required_files = { "artisan", "composer.json", "routes" } -- Pas dit aan op basis van je behoeften

	for _, file in ipairs(required_files) do
		local full_path = vim.fn.getcwd() .. "/" .. file
		if vim.fn.isdirectory(full_path) == 0 and vim.fn.filereadable(full_path) == 0 then
			return false
		end
	end

	return true
end


return source

