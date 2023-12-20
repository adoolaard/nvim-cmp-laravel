local cmp_laravel_routes = require('laravel-autocomplete.cmp_laravel_routes')

return {
  setup = function()
    require('cmp').register_source('laravel_routes', cmp_laravel_routes)
  end,
}
