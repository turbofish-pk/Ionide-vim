local M = {}

-- deprecated
local setup_warned = false
function M.setup(config)
  if not setup_warned then
    vim.deprecate(
      "require('ionide').setup(opts)",
      "vim.lsp.config('ionide', opts) and vim.lsp.enable('ionide')",
      "a future release",
      "Ionide-vim"
    )
    setup_warned = true
  end
  vim.lsp.config.ionide = require("ionide.config").make_config()
  if config and next(config) ~= nil then
    vim.lsp.config("ionide", config)
  end
  vim.lsp.enable("ionide")
end

function M.status()
  local clients = vim.lsp.get_clients({ name = "ionide" })
  if #clients == 0 then
    print("* LSP server: not started")
  else
    print("* LSP server: started")
  end
end

function M.call(method, params, callback_key)
  local handler = function(err, result, ctx)
    if result ~= nil then
      vim.fn['fsharp#resolve_callback'](callback_key, {
        result = result,
        err = err,
        client_id = ctx.client_id,
        bufnr = ctx.bufnr
      })
    end
  end
  vim.lsp.buf_request(0, method, params, handler)
end

function M.notify(method, params)
  vim.lsp.buf_notify(0, method, params)
end

return M
