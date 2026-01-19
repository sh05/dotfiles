local tn_colors = require("tokyonight.colors")
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        "norcalli/nvim-colorizer.lua",
        config = function()
          require("colorizer").setup()
        end,
      },
    },
    main = "nvim-treesitter.configs",
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
      opts.options.theme = "auto"

      local icons = LazyVim.config.icons
      icons.Ghost = require("config.icons").get("misc", false).Ghost
      icons.Pencil = require("config.icons").get("ui", false).Pencil

      opts.sections = vim.tbl_extend("force", opts.sections, {
        lualine_a = {
          {
            function()
              return icons.Ghost
            end,
          },
        },
        lualine_c = {
          LazyVim.lualine.root_dir(),
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { LazyVim.lualine.pretty_path({ modified_sign = " " .. icons.Pencil, length = 10 }) },
        },
        lualine_y = {
          "progress",
        },
        lualine_z = { "location" },
      })
      -- do not add trouble symbols if aerial is enabled
      -- And allow it to be overriden for some buffer types (see autocmds)
      if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
        local trouble = require("trouble")
        local symbols = trouble.statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true },
          format = "{kind_icon}{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols and symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end
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
