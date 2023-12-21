local cmp = require('cmp')
local cmp_laravel_routes = require('nvim-cmp-laravel.cmp_laravel_routes')
print("Setting up Laravel autocomplete...")

local function setup()
  -- Registreer de Laravel routes source
  cmp.register_source('laravel_routes', cmp_laravel_routes.new())

  -- Voeg de Laravel routes source toe aan de lijst van nvim-cmp sources
  local sources = cmp.get_config().sources or {}
    if cmp_laravel_routes.get_trigger_characters() then
        table.insert(sources, { name = 'laravel_routes', trigger_characters = cmp_laravel_routes.get_trigger_characters(), keyword_length = cmp_laravel_routes.get_keyword_length(), keyword_pattern = cmp_laravel_routes.get_keyword_pattern()})
    else
        table.insert(sources, { name = 'laravel_routes', keyword_length = cmp_laravel_routes.get_keyword_length(), keyword_pattern = cmp_laravel_routes.get_keyword_pattern()})
  -- table.insert(sources, { name = 'laravel_routes', trigger_characters = cmp_laravel_routes.get_trigger_characters(), keyword_length = cmp_laravel_routes.get_keyword_length(), keyword_pattern = cmp_laravel_routes.get_keyword_pattern()})
  cmp.setup({ sources = sources })
end

return {
  setup = setup,
}
