local cmp = require("cmp")
local Job = require("plenary.job")

local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
	return setmetatable({}, { __index = source })
end

-- Deze functie wordt aangeroepen door nvim-cmp om de beschikbare items te krijgen
-- function source.complete(self, request, callback)
-- 	local context = request.context
-- 	local line = context.cursor_before_line
-- 	local cursor_col = context.cursor.col
--
-- 	-- Check of de lijn eindigt met " route('"
-- 	if string.sub(line, 1, cursor_col - 1):match("route%('") then
-- 		local routes = source.get_laravel_routes() -- Haal routes op
-- 		callback({ items = routes }) -- Geef de routes terug aan nvim-cmp
-- 	else
-- 		callback({ items = { "geen routes " } }) -- Geen matches, geef een lege lijst terug
-- 	end
-- end
function source.complete(self, request, callback)
	local context = request.context
	local line = context.cursor_before_line
	local cursor_col = context.cursor.col

	-- Haal de huidige invoer op na "route('"
	local _, route_prefix_end = line:find("route%('")
	local current_input = route_prefix_end and line:sub(route_prefix_end + 1, cursor_col - 1) or ""

	-- Haal routes op
	local routes = source.get_laravel_routes()

	-- Filter de routes op basis van de huidige invoer
	local filtered_routes = {}
	for _, route in ipairs(routes) do
		if route.label:sub(1, #current_input) == current_input then
			table.insert(filtered_routes, route)
		end
	end

	callback({ items = filtered_routes })
end


-- Check de framework versie. Met "php artisan --version" staat er in een Lumen project ook "Lumen"

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

	-- Return two booleans: is_laravel, is_lumen
	return is_laravel, is_lumen
end

-- Haal Laravel routes op en gebruik is_laravel() om te checken of het een Laravel project is. Verander de regex om de juiste routes te krijgen.
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
                    table.insert(routes, { label = route_name, kind = cmp.lsp.CompletionItemKind.Text })
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

-- Deze functie wordt gebruikt door nvim-cmp om de source te identificeren
function source.get_keyword_pattern()
	-- return [[\w+]]
	return [[\croute('\w+]]
end

-- Minimale lengte van de keyword om de source te triggeren
function source.get_keyword_length()
	return 3
end

-- function source.get_keyword_pattern()
-- 	return [[\%(\croute('\)\@<=\k*]]
-- end
--
-- function source.get_keyword_length()
-- 	return 1
-- end


-- Deze functie wordt gebruikt door nvim-cmp voor het sorteren van items
-- function source.get_trigger_characters()
-- 	return { "." } -- Pas dit aan indien nodig voor je use-case
-- end
function source.get_trigger_characters()
	return { "'", "(", "." } -- Voeg enkele extra tekens toe die relevant zijn
end

-- Deze functie wordt gebruikt om de source te identificeren (optioneel)
function source.is_available()
	return true
end

return source
