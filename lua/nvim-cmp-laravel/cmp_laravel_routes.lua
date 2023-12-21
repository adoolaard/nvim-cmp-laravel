local cmp = require("cmp")
local Job = require("plenary.job")

local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
	return setmetatable({}, { __index = source })
end

function source.complete(self, request, callback)
	local context = request.context
	local line = context.cursor_before_line
	local cursor_col = context.cursor.col

	-- Check of de lijn eindigt met " route('"
	if string.sub(line, 1, cursor_col - 1):match("route%('") then
		source.get_laravel_routes(function(routes)
			callback({ items = routes }) -- Geef de routes terug aan nvim-cmp
		end)
	else
		callback({ items = {} }) -- Geen matches, geef een lege lijst terug
	end
end

function source.is_laravel(callback)
	local job = Job:new({
		command = "php",
		args = { "artisan", "--version" },
		cwd = vim.loop.cwd(),
		on_exit = function(j, return_val)
			local result = j:result()
			if return_val == 0 then
				local version_output = table.concat(result, " ")
				if version_output:match("Laravel Framework") then
					callback(true, version_output:match("Lumen") ~= nil)
				else
					callback(false, false)
				end
			else
				callback(false, false)
			end
		end,
	})

	job:start()
end

function source.get_laravel_routes(callback)
	source.is_laravel(function(is_laravel, is_lumen)
		if not is_laravel then
			print("Dit is geen Laravel of Lumen project.")
			callback({})
			return
		end

		local artisan_command = "route:list --method=GET"
		if is_lumen then
			print("Het is een Lumen project.")
			artisan_command = "route:list --columns=Verb --columns=NamedRoute --method=GET"
        else
            print("Het is een Laravel project.")
        end

		local job = Job:new({
			command = "php",
			args = { "artisan", artisan_command },
			cwd = vim.loop.cwd(),
			on_stdout = function(_, line)
				if is_lumen then
					-- Lumen route parsing
					local verb, route = line:match("| (%w+)%s+| ([%w%.%-_]+)%s+|")
					if verb == "GET" and route then
						table.insert(routes, { label = route, kind = cmp.lsp.CompletionItemKind.Text })
					end
				else
					-- Laravel route parsing
					local route = line:match("%s+GET|HEAD%s+([%w/%-_%.:]+)%s+")
					if route then
						table.insert(routes, { label = route, kind = cmp.lsp.CompletionItemKind.Text })
					end
				end
			end,
			on_exit = function(j, return_val)
				if return_val == 0 then
					callback(routes)
				else
					vim.notify("Kan route lijst niet ophalen.")
					callback({})
				end
			end,
		})

		job:start()
	end)
end

function source.get_keyword_pattern()
	return [[\croute('\w+]]
end

function source.get_keyword_length()
	return 3
end

function source.get_trigger_characters()
	return { "'", "(", "." }
end

function source.is_available()
	return true
end

return source
