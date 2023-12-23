local cmp = require("cmp")
local cmp_laravel_routes = require("nvim-cmp-laravel.cmp_laravel_routes")
local cmp_laravel_views = require("nvim-cmp-laravel.cmp_laravel_views")
print("Setting up Laravel autocomplete...")

local function setup()
	cmp.register_source("laravel_routes", cmp_laravel_routes.new())

	local sources = cmp.get_config().sources or {}
	table.insert(
		sources,
		{
			name = "laravel_routes",
			-- trigger_characters = cmp_laravel_routes.get_trigger_characters(),
			-- keyword_length = cmp_laravel_routes.get_keyword_length(),
			-- keyword_pattern = cmp_laravel_routes.get_keyword_pattern(),
		}
	)
	cmp.setup({ sources = sources })
end

return {
	setup = setup,
}
