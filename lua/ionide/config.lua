local M = {}

local function create_handlers()
  local handlers = vim.fn["fsharp#get_handlers"]()
  local result = {}

  for method, func_name in pairs(handlers) do
    result[method] = function(_, params, ctx)
      if params == nil or method ~= ctx.method then
        return
      end
      vim.fn[func_name](params)
    end
  end

  return result
end

local function with_codelens_refresh(on_attach)
  return function(client, bufnr)
    if on_attach then
      on_attach(client, bufnr)
    end
    vim.lsp.codelens.refresh({ bufnr = bufnr })
  end
end

local function with_workspace_did_change_configuration(on_init)
  return function(client, result)
    if on_init then
      on_init(client, result)
    end

    function client.workspace_did_change_configuration(settings)
      if not settings then
        return
      end
      if vim.tbl_isempty(settings) then
        settings = { [vim.type_idx] = vim.types.dictionary }
      end
      return client.notify("workspace/didChangeConfiguration", {
        settings = settings,
      })
    end

    if not vim.tbl_isempty(client.config.settings or {}) then
      client.workspace_did_change_configuration(client.config.settings)
    end
  end
end

local function find_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local startpath = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
  local root = vim.fs.root(startpath, function(entry)
    return entry == ".git"
      or entry:match("%.sln$")
      or entry:match("%.slnx$")
      or entry:match("%.fsproj$")
      or entry:match("%.fsx$")
  end)

  return root or startpath or vim.uv.cwd()
end

function M.make_config()
  vim.fn["fsharp#loadConfig"]()

  return {
    name = "ionide",
    cmd = vim.g["fsharp#fsautocomplete_command"],
    cmd_env = { DOTNET_ROLL_FORWARD = "LatestMajor" },
    filetypes = { "fsharp" },
    root_dir = function(bufnr, on_dir)
      on_dir(find_root(bufnr))
    end,
    handlers = create_handlers(),
    init_options = {
      AutomaticWorkspaceInit = vim.g["fsharp#automatic_workspace_init"] == 1,
    },
    on_init = with_workspace_did_change_configuration(function()
      vim.fn["fsharp#initialize"]()
    end),
    on_attach = with_codelens_refresh(nil),
  }
end

return M
