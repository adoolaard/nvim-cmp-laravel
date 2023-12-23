local cmp = require("cmp")
local Job = require("plenary.job")

local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
	return setmetatable({}, { __index = source })
end

-- Functie om alleen de modelnamen op te halen
function source.get_laravel_model_names()
    local models = {}
    local models_path = vim.fn.getcwd() .. "/app/Models"

    -- Check if models path exists and is a directory
    if vim.fn.isdirectory(models_path) == 0 then
        vim.notify("Models directory not found.")
        return models
    end

    -- Recursively list all files in the models directory
    local handle = io.popen("find '" .. models_path .. "' -type f -name '*.php'")
    if handle then
        local result = handle:read("*all")
        handle:close()

        for model_path in string.gmatch(result, "[^\r\n]+") do
            local model_name = model_path:sub(#models_path + 2, -5):gsub("/", "\\")
            table.insert(models, {
                -- label = "model('" .. model_name .. "')",
                label = "model('" .. model_name,
                kind = cmp.lsp.CompletionItemKind.Class,
            })
        end
    else
        vim.notify("Could not read models directory.")
    end

    return models
end

-- Functie om de attributen van een specifiek model op te halen
function source.get_model_attributes(model_name)
    local attributes = {}
    local command = "php artisan model:show " .. model_name .. " --json"
    local model_handle = io.popen(command)
    if model_handle then
        local model_info = model_handle:read("*all")
        model_handle:close()

        -- Parse the JSON output
        local ok, parsed = pcall(vim.fn.json_decode, model_info)
        if ok and parsed and parsed.attributes then
            for _, attribute in ipairs(parsed.attributes) do
                local attribute_name = attribute.name
                if attribute_name then
                    local full_name = model_name .. "." .. attribute_name
                    table.insert(attributes, {
                        label = full_name,
                        kind = cmp.lsp.CompletionItemKind.Property,
                    })
                end
            end
        else
            vim.notify("Failed to parse model information for '" .. model_name .. "'.")
        end
    else
        vim.notify("Could not execute artisan command for model '" .. model_name .. "'.")
    end
    return attributes
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
                -- label = "view('" .. view_name .. "')",
                label = "view('" .. view_name,
                kind = cmp.lsp.CompletionItemKind.Text,
            })
        end
    else
        vim.notify("Could not read views directory.")
    end

    return views
end

function source.is_laravel()
	local is_laravel = false
	local is_lumen = false

	local job = Job:new({
		command = "php",
		args = { "artisan", "--version" },
		cwd = vim.loop.cwd(),
		on_exit = function(j, return_val)
			local result = j:result()
			if return_val == 0 then
				local version_output = table.concat(result, " ")
				if version_output:match("Laravel Framework") then
					if version_output:match("Lumen") then
						is_lumen = true
					else
						is_laravel = true
					end
				end
			end
		end,
	})

	job:sync() -- This will wait for the job to finish

	return is_laravel, is_lumen
end


function source.get_laravel_routes()
	local routes = {}
	local is_laravel, is_lumen = source.is_laravel()

	local command
	if is_laravel then
		print("Dit is een Laravel project.")
		command = "php artisan route:list --method=GET --no-ansi --json"
	elseif is_lumen then
		print("Het is een Lumen project.")
		command = "php artisan route:list --method=get --columns=NamedRoute --json"
	else
		print("Dit is geen Laravel of Lumen project.")
		return routes
	end

	local handle = io.popen(command, "r")
	if handle then
		local result = handle:read("*all")
		handle:close()

		local success, parsed = pcall(vim.fn.json_decode, result)
		if success then
			for _, route in ipairs(parsed) do
				local route_name
				if is_laravel then
					route_name = route.name
				elseif is_lumen then
					route_name = route.namedRoute
				end

				if route_name then
					table.insert(routes, {
						label = "route('" .. tostring(route_name),
						kind = cmp.lsp.CompletionItemKind.laravel_routes,
					})
				end
			end
		else
			vim.notify("Kon de JSON output niet parsen.")
		end
	else
		vim.notify("Kon het Artisan commando niet uitvoeren.")
	end

	return routes
end

-- Update de complete functie om de nieuwe logica te gebruiken
function source:complete(params, callback)
    local cursor_before_line = string.sub(params.context.cursor_before_line, 1, params.offset - 1)

    if cursor_before_line:match("route%('$") then
        local routes = source.get_laravel_routes()
        callback({ items = routes, isIncomplete = true })
    elseif cursor_before_line:match("return view%('$") then
        local views = source.get_laravel_views()
        callback({ items = views, isIncomplete = true })
    elseif cursor_before_line:match("model%('$") then
        -- We only have "model('", suggest model names
        local models = source.get_laravel_model_names()
        callback({ items = models, isIncomplete = true })
    elseif cursor_before_line:match("model%('([%w\\_%.]+)'%.") then
        -- We have "model('ModelName').", extract the model name and suggest attributes
        local model_name = cursor_before_line:match("model%('([%w\\_%.]+)'%.")
        local attributes = source.get_model_attributes(model_name)
        callback({ items = attributes, isIncomplete = true })
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

