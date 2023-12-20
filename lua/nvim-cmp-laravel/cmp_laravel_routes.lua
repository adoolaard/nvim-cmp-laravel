local cmp = require('cmp')
local Job = require'plenary.job'


local source = {}

-- Deze functie wordt aangeroepen door nvim-cmp om de source te initialiseren
function source.new()
  return setmetatable({}, { __index = source })
end

-- Deze functie wordt aangeroepen door nvim-cmp om de beschikbare items te krijgen
function source.complete(self, request, callback)
  local routes = source.get_laravel_routes()  -- Roep je functie aan om de routes op te halen
  callback({ items = routes })  -- Geef de routes terug aan nvim-cmp
end

function get_framework_version(callback)
  Job:new({
    command = 'php',
    args = {'artisan', '--version'},
    on_exit = function(j, return_val)
      local result = j:result()
      local output = table.concat(result, " ")
      if string.match(output, "Lumen") then
        callback('lumen')
      else
        callback('laravel')
      end
    end,
  }):start()
end

function source.get_laravel_routes(callback)
  get_framework_version(function(framework)
    local routes = {}
    local routes_php_path = vim.loop.cwd() .. (framework == 'laravel' and '/routes/web.php' or '/app/Http/routes.php')

    local file = io.open(routes_php_path, "r")
    if file then
      local content = file:read("*all")
      file:close()

      for alias in string.gmatch(content, "%'as'%s*=>%s*%'([^']+)%'") do
        table.insert(routes, { label = alias, kind = cmp.lsp.CompletionItemKind.Text })
      end
    else
      vim.notify("Kon het bestand niet openen: " .. routes_php_path)
    end

    callback(routes)
  end)
end
-- Deze functie wordt gebruikt door nvim-cmp om de source te identificeren
function source.get_keyword_pattern()
  return [[\w+]]  -- Pas dit aan indien nodig voor je use-case
end

-- Deze functie wordt gebruikt door nvim-cmp voor het sorteren van items
function source.get_trigger_characters()
  return { "." }  -- Pas dit aan indien nodig voor je use-case
end

-- Deze functie wordt gebruikt om de source te identificeren (optioneel)
function source.is_available()
  return true
end

return source
