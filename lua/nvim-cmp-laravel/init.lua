local cmp = require('cmp')
local cmp_laravel_routes = require('nvim-cmp-laravel.cmp_laravel_routes')
print("Setting up Laravel autocomplete...")

local function setup()
  -- Registreer de Laravel routes source
  cmp.register_source('laravel_routes', cmp_laravel_routes.new())

  -- Voeg de Laravel routes source toe aan de lijst van nvim-cmp sources
  local sources = cmp.get_config().sources or {}
  -- table.insert(sources, { name = 'laravel_routes' })
  table.insert(sources, { name = 'laravel_routes', trigger_characters = cmp_laravel_routes.get_trigger_characters() })
  cmp.setup({ sources = sources })
end

return {
  setup = setup,
}
