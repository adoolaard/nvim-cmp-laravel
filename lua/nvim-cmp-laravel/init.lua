local cmp = require("cmp")
local cmp_laravel_routes = require("nvim-cmp-laravel.cmp_laravel_routes")
-- local cmp_laravel_views = require("nvim-cmp-laravel.cmp_laravel_views")
print("Setting up Laravel autocomplete...")

local function setup()
	cmp.register_source("laravel_routes", cmp_laravel_routes.new())
    -- cmp.register_source("laravel_views", cmp_laravel_views.new())

	local sources = cmp.get_config().sources or {}
	table.insert(
		sources,
		{
			name = "laravel_routes",
            name = "laravel_views",
		}
	)
	cmp.setup({ sources = sources })
end

return {
	setup = setup,
}
