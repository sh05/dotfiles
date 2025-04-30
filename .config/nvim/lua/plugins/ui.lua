local colors = require("tokyonight.colors").setup({ style = "night" })

return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      {
        "norcalli/nvim-colorizer.lua",
        config = function()
          require("colorizer").setup()
        end,
      },
    },
    opts = function(_, opts)
      opts.ensure_installed = vim.list_extend(opts.ensure_installed, {
        "cue",
        "elm",
        "go",
        "gomod",
        "hcl",
        "julia",
        "rego",
        "rust",
        "starlark",
        "terraform",
      })
      return opts
    end,
    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        ---@type table<string, boolean>
        local added = {}
        opts.ensure_installed = vim.tbl_filter(function(lang)
          if added[lang] then
            return false
          end
          added[lang] = true
          return true
        end, opts.ensure_installed)
      end
      require("nvim-treesitter.configs").setup(opts)

      -- additional config
      vim.treesitter.language.register("starlark", "tiltfile")
    end,
  },
  {
    "folke/noice.nvim",
    enabled = true,
    opts = {
      cmdline = {
        view = "cmdline_popup",
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      { "folke/tokyonight.nvim" },
    },
    opts = function(_, opts)
      local icons = {
        ui = require("config.icons").get("ui", false),
      }

      local mode_color = {
        n = colors.blue,
        i = colors.green,
        v = colors.purple,
        [""] = colors.purple,
        V = colors.purple,
      }

      opts.sections = vim.tbl_extend("force", opts.sections, {
        lualine_a = {
          {
            function()
              return icons.ui.Devil
            end,
            color = function()
              return {
                fg = mode_color[vim.fn.mode()],
                bg = colors.bg,
              }
            end,
          },
        },
        lualine_x = {
          { require("mcphub.extensions.lualine") },
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      })
      return opts
    end,
  },
  {
    "akinsho/bufferline.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
    },
    opts = {
      options = {
        buffer_close_icon = require("config.icons").get("ui", false).Close,
      },
    },
  },
}
