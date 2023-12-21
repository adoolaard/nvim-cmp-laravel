local cmp = require("cmp")
local Job = require("plenary.job")

local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
	return setmetatable({}, { __index = source })
end

-- Deze functie wordt aangeroepen door nvim-cmp om de beschikbare items te krijgen
-- function source.complete(self, request, callback)
-- 	local routes = source.get_laravel_routes() -- Roep je functie aan om de routes op te halen
-- 	callback({ items = routes }) -- Geef de routes terug aan nvim-cmp
-- end
function source.complete(self, request, callback)
	local context = request.context
	local line = context.cursor_before_line
	local cursor_col = context.cursor.col

	-- Check of de lijn eindigt met " route('"
	if string.sub(line, 1, cursor_col - 1):match("route%('") then
		local routes = source.get_laravel_routes() -- Haal routes op
		callback({ items = routes }) -- Geef de routes terug aan nvim-cmp
	else
		callback({ items = { "geen routes " } }) -- Geen matches, geef een lege lijst terug
	end
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

	-- Voer het juiste artisan commando uit op basis van of het Laravel of Lumen is
	local command
	if is_laravel then
		print("Dit is een Laravel project.")
		command = "php artisan route:list --method=GET --no-ansi "
	elseif is_lumen then
		print("Het is een Lumen project.")
		command = "php artisan route:list --method=get --columns=NamedRoute"
	else
		print("Dit is geen Laravel of Lumen project.")
		return routes
	end

	-- Voer het commando uit en vang de output op
	local handle = io.popen(command, "r")
	if handle then
		local result = handle:read("*all")
		handle:close()

		-- Verwerk de output en extraher de route namen
		for line in string.gmatch(result, "[^\r\n]+") do
			local route_name
			if is_laravel then
				-- Match de eerste naam voor de '>'
				route_name = line:match("%s+GET|HEAD%s+[%w/_-]+%s+.-%s+([%w._-]+)%s+›")
			elseif is_lumen then
				route_name = line:match("|%s*(%S+)%s*|")
			end

			if route_name and not route_name:match("^+%-+$") and route_name ~= "NamedRoute" then
				-- Voeg de route naam toe aan de lijst met routes
				table.insert(routes, { label = route_name, kind = cmp.lsp.CompletionItemKind.Text })
			end
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
