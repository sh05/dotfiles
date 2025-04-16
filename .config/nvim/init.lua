-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- ファイルの末尾に改行を強制する設定
vim.o.eol = true
vim.o.fixendofline = true
-- import順のチェックを無効化
vim.g.lazyvim_check_order = false
