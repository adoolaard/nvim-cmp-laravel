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
	local job = Job:new({
		command = "php",
		args = { "artisan", "--version" },
		cwd = vim.loop.cwd(),
		on_exit = function(j, return_val)
			if return_val == 0 then
				return true
			else
				return false
			end
		end,
	})

	local result = job:sync()
	return result[1] == "Laravel Framework"
end

-- Haal Laravel routes op
-- function source.get_laravel_routes()
--   local routes = {}
--   -- Verkrijg de huidige werkdirectory en voeg de pad naar het routes bestand toe
--   local routes_php_path = vim.loop.cwd() .. '/routes/web.php'
--
--   local file = io.open(routes_php_path, "r")
--   if file then
--     local content = file:read("*all")
--     file:close()
--
--     for alias in string.gmatch(content, "%'as'%s*=>%s*%'([^']+)%'") do
--       -- Gebruik een statische waarde voor 'kind' of laat het weg
--       table.insert(routes, { label = alias, kind = cmp.lsp.CompletionItemKind.Text })
--     end
--   else
--     vim.notify("Kon het bestand niet openen: " .. routes_php_path)
--   end
--
--   return routes
-- end

-- Haal Laravel routes op en gebruik is_laravel() om te checken of het een Laravel project is. Verander de regex om de juiste routes te krijgen.
function source.get_laravel_routes()
	local routes = {}
	-- Verkrijg de huidige werkdirectory en voeg de pad naar het routes bestand toe
	local routes_php_path = vim.loop.cwd() .. "/routes/web.php"

	local file = io.open(routes_php_path, "r")
	if file then
		local content = file:read("*all")
		file:close()

		if source.is_laravel() then
			print("Laravel project")
			for alias in string.gmatch(content, "->name%('([^']*)'%)") do
				-- Gebruik een statische waarde voor 'kind' of laat het weg
				table.insert(routes, { label = alias, kind = cmp.lsp.CompletionItemKind.Text })
			end
		else
			print("Lumen project")
			for alias in string.gmatch(content, "%'as'%s*=>%s*%'([^']+)%'") do
				-- Gebruik een statische waarde voor 'kind' of laat het weg
				table.insert(routes, { label = alias, kind = cmp.lsp.CompletionItemKind.Text })
			end
		end
	else
		vim.notify("Kon het bestand niet openen: " .. routes_php_path)
	end

	return routes
end

-- Deze functie wordt gebruikt door nvim-cmp om de source te identificeren
function source.get_keyword_pattern()
	return [[\w+]] -- Pas dit aan indien nodig voor je use-case
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
