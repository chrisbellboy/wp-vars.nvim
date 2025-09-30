# wp-vars.nvim

Add WordPress theme.json CSS custom properties to nvim-cmp.

## Installation

Add it as a dependency of `hrsh7th/nvim-cmp`.

### [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) config.

```lua
{
  "hrsh7th/nvim-cmp",
  dependencies = {
    -- Other dependencies...
    {
      "chrisbellboy/wp-vars.nvim",
      opts = {
        -- cmp_filetypes = { "css", "scss" }, -- Optional: customize filetypes
        -- preset_mappings = {}, -- Optional: extend default mappings
      },
    },
  },
  config = function()
     cmp.setup({
      sources = cmp.config.sources({
        { name = "wp_vars" }, -- Place near the top for higher priority.
        { name = "nvim_lsp" },
        -- Other sources...
      }),
    })
    -- Other cmp config...
  end
}
```

## Features

The plugin parses WordPress `theme.json` files and adds wp preset css completions to `nvim-cmp`.

**Default preset mappings the plugin searches for:**

- **Colors**: `color.palette` = `--wp--preset--color--{slug}`
- **Spacing**: `spacing.spacingSizes` = `--wp--preset--spacing--{slug}`
- **Font Sizes**: `typography.fontSizes` = `--wp--preset--font-size--{slug}`
- **Font Families**: `typography.fontFamilies` = `--wp--preset--font-family--{slug}`

## Configuration

### Theme File Location

The plugin automatically looks for `theme.json` files:

1. Looks for `{PACKAGE_NAME}/theme.json` (using package.json name)
2. **Fallback**: Searches for any `theme.json` files in the pwd (respecting .gitignore)

### Custom Preset Mappings

Extend the default mappings:

```lua
preset_mappings = {
  -- defaults are included automatically
  { path = "custom.gradients", preset_type = "gradient", value_key = "gradient" },
  -- Override sort order
  { path = "spacing.spacingSizes", preset_type = "spacing", value_key = "size", sort_key = "slug" },
}
```

**`preset_mappings` options:**

- `path`: Dot notation path in theme.json.
- `preset_type`: Used in CSS variable name.
- `value_key`: Field containing the CSS value.
- `sort_key`: (Optional) Theme.json key to use for nvim-cmp sort order. Defaults to `name` field with a fallback to `slug`.

## Credits

- Inspired by [css-vars.nvim](https://github.com/jdrupal-dev/css-vars.nvim) (Thanks!)
