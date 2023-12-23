local cmp = require("cmp")
local Job = require("plenary.job")

local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
	return setmetatable({}, { __index = source })
end

function source.get_laravel_views()
    local views = {}
    local views_path = vim.fn.getcwd() .. "/resources/views"

    -- Check if views path exists and is a directory
    if vim.fn.isdirectory(views_path) == 0 then
        vim.notify("Views directory not found.")
        return views
    end

    -- Recursively list all files in the views directory
    local handle = io.popen("find '" .. views_path .. "' -type f -name '*.blade.php'")
    if handle then
        local result = handle:read("*all")
        handle:close()

        for view_path in string.gmatch(result, "[^\r\n]+") do
            local view_name = view_path:sub(#views_path + 2, -11):gsub("/", ".")
            table.insert(views, {
                label = "view('" .. view_name .. "')",
                kind = cmp.lsp.CompletionItemKind.Text,
            })
        end
    else
        vim.notify("Could not read views directory.")
    end

    return views
end

-- Update the complete function
function source:complete(params, callback)
    -- Check if the input matches "route('" or "return view('"
    local cursor_before_line = string.sub(params.context.cursor_before_line, 1, params.offset - 1)
    if cursor_before_line:match("route%('$") then
        local routes = source.get_laravel_routes()
        callback({ items = routes, isIncomplete = true })
    elseif cursor_before_line:match("return view%('$") then
        local views = source.get_laravel_views()
        callback({ items = views, isIncomplete = true })
    else
        callback({ items = {}, isIncomplete = false })
    end
end

function source.get_trigger_characters()
	return { "'" }
end

-- Deze functie wordt gebruikt om de source te identificeren (optioneel)
-- function source.is_available()
-- 	return vim.bo.filetype == "php" and source.has_laravel_files()
-- end

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

