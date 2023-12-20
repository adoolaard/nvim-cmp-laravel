local cmp = require("cmp")
local Job = require("plenary.job")

local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
	return setmetatable({}, { __index = source })
end

-- Deze functie wordt aangeroepen door nvim-cmp om de beschikbare items te krijgen
function source.complete(self, request, callback)
	local routes = source.get_laravel_routes() -- Roep je functie aan om de routes op te halen
	callback({ items = routes }) -- Geef de routes terug aan nvim-cmp
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
					is_laravel = true
					if version_output:match("Lumen") then
						is_lumen = true
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
	-- Verkrijg de huidige werkdirectory en voeg de pad naar het routes bestand toe
	local routes_php_path = vim.loop.cwd() .. "/routes/web.php"

	local file = io.open(routes_php_path, "r")
	if file then
		local content = file:read("*all")
		file:close()

		local is_laravel, is_lumen = source.is_laravel()
		if is_laravel then
			print("Dit is een Laravel project.")
			for alias in string.gmatch(content, "->name%('([^']*)'%)") do
				-- Gebruik een statische waarde voor 'kind' of laat het weg
				table.insert(routes, { label = alias, kind = cmp.lsp.CompletionItemKind.Text })
			end

			if is_lumen then
				print("Het is een Lumen project.")
                for alias in string.gmatch(content, "%'as'%s*=>%s*%'([^']+)%'") do
                    -- Gebruik een statische waarde voor 'kind' of laat het weg
                    table.insert(routes, { label = alias, kind = cmp.lsp.CompletionItemKind.Text })
                end
			end
		else
			print("Dit is geen Laravel of Lumen project.")
		end
	else
		vim.notify("Kon het bestand niet openen: " .. routes_php_path)
	end

	return routes
end

-- Deze functie wordt gebruikt door nvim-cmp om de source te identificeren
function source.get_keyword_pattern()
	-- return [[\w+]]
    -- return [[\croute\w*]]
    return [[\croute\w*|\{\{\s*route\(['"]]]
end

-- Minimale lengte van de keyword om de source te triggeren
function source.get_keyword_length()
    return 3
end

-- Deze functie wordt gebruikt door nvim-cmp voor het sorteren van items
function source.get_trigger_characters()
	return { "." } -- Pas dit aan indien nodig voor je use-case
end

-- Deze functie wordt gebruikt om de source te identificeren (optioneel)
function source.is_available()
	return true
end

return source
