-- port of refactored fsharp.vim to lua
-- only neovim 0.12+ is supported

local M = {}

function M.notify(method, params)
  -- vim.notify("fsharp.notify -> " .. method) -- temporary side effect for testing only
  require("ionide").notify(method, params)
end

function M.hover()
  vim.notify("fsharp_vim.hover -> " .. "hello") -- temporary side effect for testing only
  vim.lsp.buf.hover()
end

return M
