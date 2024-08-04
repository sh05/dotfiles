-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local opt = vim.opt

local function augroup(name)
  return vim.api.nvim_create_augroup("mylazyvim_" .. name, { clear = true })
end

-- tabstop,shiftwidth = 4 for some filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("tab4"),
  pattern = { "elm", "yaml" },
  callback = function()
    opt.tabstop = 4
    opt.shiftwidth = 4
    vim.b.autoformat = false
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup("tiltfile"),
  pattern = {
    "Tiltfile*",
  },
  callback = function()
    vim.opt_local.filetype = "tiltfile"
  end,
})

-- 選択範囲をポップアップウィンドウに表示し、編集後に元の場所に反映する関数
function ShowSelectionInPopup()
  -- ビジュアルモードで選択した範囲を取得
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- 選択範囲の内容を取得
  local lines = vim.fn.getbufline("%", start_pos[2], end_pos[2])

  -- ポップアップウィンドウのオプション設定
  local opts = {
    relative = "cursor",
    -- width = vim.fn.max(vim.fn.map(lines, "len(v:val)")),
    width = vim.api.nvim_win_get_width(0), -- 元のバッファの幅を使用
    height = #lines,
    col = 1,
    row = 1,
    style = "minimal",
    border = "single",
    title = "Open String as Shell",
    title_pos = "center",
  }

  -- 新しいバッファを作成
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- バッファのfiletypeをshに設定
  vim.api.nvim_buf_set_option(buf, "filetype", "sh")

  -- ポップアップウィンドウを開く
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- ポップアップウィンドウを閉じたときに編集内容を反映
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      -- 編集された内容を取得
      local edited_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- 元のバッファに編集内容を反映
      vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, edited_lines)

      -- ウィンドウを閉じる
      vim.api.nvim_win_close(win, true)
    end,
  })
end

-- ビジュアルモードで<leader>pを押すとShowSelectionInPopupを呼び出す
vim.api.nvim_set_keymap("v", "<leader>p", ":lua ShowSelectionInPopup()<CR>", { noremap = true, silent = true })
