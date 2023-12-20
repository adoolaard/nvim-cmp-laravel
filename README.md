# Laravel Autocomplete for nvim-cmp

## Installation

Using packer.nvim:

```lua
use {
  'MIJN_NAAM/laravel-autocomplete',
  requires = { 'hrsh7th/nvim-cmp' },
  config = function()
    require('laravel-autocomplete').setup()
  end
}
