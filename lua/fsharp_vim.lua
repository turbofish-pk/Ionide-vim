-- port of refactored fsharp.vim to lua
-- only neovim 0.12+ is supported

local M = {}

function M.notify(method, params)
  require("ionide").notify(method, params)
end

function M.hover()
  vim.lsp.buf.hover()
end

function M.call(method, params, key)
  require("ionide").call(method, params, key)
end

return M



-- vim.notify("fsharp_vim.call -> " .. "hello") -- temporary side effect for testing only
