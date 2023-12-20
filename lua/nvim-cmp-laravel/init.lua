local cmp_laravel_routes = require('nvim-cmp-laravel.cmp_laravel_routes')
print("Setting up Laravel autocomplete...")

return {
  setup = function()
    require('cmp').register_source('laravel_routes', cmp_laravel_routes)
  end,
}
