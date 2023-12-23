# nvim-cmp-laravel

`nvim-cmp-laravel` is a plugin designed to enhance the development workflow for Laravel projects in Neovim. It provides autocompletion for routes within blade files when you type `route('`. This plugin is an extension for `nvim-cmp`, the completion engine for Neovim. Future enhancements will include autocompletion for views (e.g., `return view('AUTOCOMPLETE_HERE)`), and other Laravel-specific features.

## Features

-[x] Autocomplete Laravel routes in blade files.

-[ ] Support for view autocompletion

-[ ] Support for database model autocompletion

-[ ] And more

## Installation

To install `nvim-cmp-laravel`, ensure you have `nvim-cmp` configured in your Neovim setup. Add the following line to your `nvim-cmp` dependencies:

```
"adoolaard/nvim-cmp-laravel",
```
After adding the plugin to your dependencies, add this at the end of the `config = function() `:
``` require("nvim-cmp-laravel").setup() ```

## Configuration
nvim-cmp-laravel is configured to be able to show custom icons for the autocomplete suggestions. This is my formatting options for nvim-cmp:
```
formatting = {
    fields = { "abbr", "kind", "menu" },
    format = function(entry, vim_item)
        -- Custom icons for specific item types
        local custom_icons = {
            copilot = icons.misc.copilot,
            laravel_routes = icons.misc.laravel_routes,
            Text = icons.ui.FindText,
        }

        -- Determine the correct icon
        local kind_label = vim_item.kind
        if entry.source.name == "copilot" then
            kind_label = "copilot"
            vim_item.kind_hl_group = "CopilotSuggestion" -- Highlight group for copilot suggestions
        elseif entry.source.name == "laravel_routes" then
            kind_label = "laravel_routes"
            vim_item.kind_hl_group = "LaravelRoutesSuggestion" -- Highlight group for laravel_routes suggestions
        end
        vim_item.kind = custom_icons[kind_label] or icons.kind[kind_label] or kind_label

        -- Set the 'menu' field with the source of the suggestion
        vim_item.menu = "(" .. (source_map[entry.source.name] or entry.source.name) .. ")"

        -- The rest remains unchanged
        -- Special handling for colors
        if vim_item.kind == icons.kind.Color and entry.completion_item.documentation then
            local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")
            if r then
                local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
                local group = "Tw_" .. color
                if vim.fn.hlID(group) < 1 then
                    vim.api.nvim_set_hl(0, group, { fg = "#" .. color })
                end
                vim_item.kind_hl_group = group
                return vim_item
            end
        end

        return vim_item
    end,
},
```

## Contribution
I am dedicating as much time as possible to developing this plugin, but I also have a life outside of coding ;). If you're able to contribute by adding features or fixing bugs, your pull requests are highly appreciated!
