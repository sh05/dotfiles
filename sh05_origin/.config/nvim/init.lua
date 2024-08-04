-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("lazy").setup({}, {
  rocks = {
    hererocks = true, -- Hererocksを有効化
    enabled = false, -- Luarocksを無効化
  },
})
